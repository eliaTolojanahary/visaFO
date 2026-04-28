package services;

import dao.DemandeDao;
import dao.PieceFournieDao;
import dao.PieceJustificativeDao;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import models.Demande;
import models.PieceFournie;
import models.PieceJustificative;
import repo.DemandeRepository;
import repo.PieceFournieRepository;
import repo.PieceJustificativeRepository;
import util.DatabaseConnection;
import util.DownloadFileResponse;
import util.FileUpload;

public class ScanService {

    private static final long MAX_FILE_SIZE = 10L * 1024L * 1024L;
    private static final Set<String> ALLOWED_MIME_TYPES = new HashSet<>();

    static {
        ALLOWED_MIME_TYPES.add("image/jpeg");
        ALLOWED_MIME_TYPES.add("image/png");
        ALLOWED_MIME_TYPES.add("application/pdf");
    }

    private final DemandeDao demandeDao;
    private final PieceFournieDao pieceFournieDao;
    private final PieceJustificativeDao pieceJustificativeDao;

    public ScanService() {
        this.demandeDao = new DemandeRepository();
        this.pieceFournieDao = new PieceFournieRepository();
        this.pieceJustificativeDao = new PieceJustificativeRepository();
    }

    public PieceFournie uploadPiece(long demandeId, long pieceRefId, FileUpload fichier) throws SQLException {
        if (fichier == null || fichier.getContent() == null || fichier.getContent().length == 0) {
            throw new IllegalArgumentException("Aucun fichier recu pour l'upload.");
        }

        Demande demande = demandeDao.findById(demandeId);
        if (demande == null) {
            throw new IllegalArgumentException("Demande introuvable: " + demandeId);
        }
        if (demande.isVerrouille()) {
            throw new DemandeVerrouilleeException("Le dossier est verrouille: aucune modification n'est autorisee.");
        }

        PieceJustificative pieceRef = pieceJustificativeDao.findById(pieceRefId);
        if (pieceRef == null) {
            throw new IllegalArgumentException("Piece justificative introuvable: " + pieceRefId);
        }
        if (!isPieceAttendue(demandeId, pieceRefId)) {
            throw new IllegalArgumentException("Cette piece n'est pas attendue pour cette demande.");
        }

        String contentType = normalizeContentType(fichier.getContentType());
        if (!ALLOWED_MIME_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Type de fichier non autorise. Autorises: jpeg, png, pdf.");
        }

        long taille = fichier.getSize() > 0 ? fichier.getSize() : fichier.getContent().length;
        if (taille > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Fichier trop volumineux (max 10 Mo).");
        }

        PieceFournie existante = pieceFournieDao.findByDemandeAndPieceRef(demandeId, pieceRefId);
        if (existante != null) {
            deleteFileQuietly(existante.getChemin_fichier());
        }

        Path targetPath = buildTargetPath(demandeId, pieceRefId, fichier.getFilename(), contentType);
        writeFile(targetPath, fichier.getContent());

        PieceFournie pieceFournie = new PieceFournie();
        pieceFournie.setDemande_id(demandeId);
        pieceFournie.setPiece_ref(pieceRef);
        pieceFournie.setChemin_fichier(targetPath.toAbsolutePath().toString());
        pieceFournie.setNom_fichier(extractSafeName(fichier.getFilename()));
        pieceFournie.setTaille_bytes(taille);
        pieceFournie.setMime_type(contentType);

        try {
            return pieceFournieDao.create(pieceFournie);
        } catch (SQLException e) {
            deleteFileQuietly(targetPath.toString());
            throw e;
        }
    }

    public boolean isDemandeComplete(long demandeId) throws SQLException {
        String sql = "SELECT COUNT(*) AS expected_count, "
            + "COUNT(pf.id) AS uploaded_count "
            + "FROM demande_piece dp "
            + "LEFT JOIN piece_fournie pf "
            + "ON pf.demande_id = dp.demande_id AND pf.piece_ref_id = dp.piece_id "
            + "WHERE dp.demande_id = ? AND dp.cochee = TRUE";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    long expected = rs.getLong("expected_count");
                    long uploaded = rs.getLong("uploaded_count");
                    return expected == 0 || uploaded >= expected;
                }
            }
        }

        return true;
    }

    public void verrouillerDemande(long demandeId) throws SQLException {
        Demande demande = demandeDao.findById(demandeId);
        if (demande == null) {
            throw new IllegalArgumentException("Demande introuvable: " + demandeId);
        }
        if (demande.isVerrouille()) {
            return;
        }

        if (!isDemandeComplete(demandeId)) {
            throw new IllegalStateException("Impossible de verrouiller: toutes les pieces attendues ne sont pas scannees.");
        }

        String updateSql = "UPDATE demande "
            + "SET verrouille = TRUE, "
            + "statut_id = (SELECT id FROM statut_demande WHERE UPPER(libelle) = UPPER(?) LIMIT 1), "
            + "updated_at = NOW() "
            + "WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(updateSql)) {
            stmt.setString(1, "Scan termine");
            stmt.setLong(2, demandeId);
            int updated = stmt.executeUpdate();
            if (updated == 0) {
                throw new SQLException("Aucune demande verrouillee pour l'id " + demandeId);
            }
        }
    }

    public Map<String, Object> getDemandeScanInfo(long demandeId) throws SQLException {
        String sql = "SELECT d.id AS demande_id, d.ref_demande, d.verrouille, "
            + "sd.libelle AS statut_libelle, dm.nom, dm.prenom "
            + "FROM demande d "
            + "JOIN statut_demande sd ON sd.id = d.statut_id "
            + "JOIN passeport p ON p.id = d.passeport_id "
            + "JOIN demandeur dm ON dm.id = p.demandeur_id "
            + "WHERE d.id = ? "
            + "LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Map<String, Object> info = new HashMap<>();
                info.put("demandeId", rs.getLong("demande_id"));
                info.put("refDemande", rs.getString("ref_demande"));
                info.put("verrouille", rs.getBoolean("verrouille"));
                info.put("statutLibelle", rs.getString("statut_libelle"));
                info.put("nom", rs.getString("nom"));
                info.put("prenom", rs.getString("prenom"));
                return info;
            }
        }
    }

    public List<Map<String, Object>> getListePiecesAttendues(long demandeId) throws SQLException {
        String sql = "SELECT p.id AS piece_ref_id, p.libelle AS piece_libelle, "
            + "pf.id AS piece_fournie_id, pf.nom_fichier, pf.taille_bytes, pf.mime_type, pf.uploaded_at "
            + "FROM demande_piece dp "
            + "JOIN piece_justificative_ref p ON p.id = dp.piece_id "
            + "LEFT JOIN piece_fournie pf ON pf.demande_id = dp.demande_id AND pf.piece_ref_id = p.id "
            + "WHERE dp.demande_id = ? AND dp.cochee = TRUE "
            + "ORDER BY p.id";

        List<Map<String, Object>> liste = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("pieceRefId", rs.getLong("piece_ref_id"));
                    item.put("pieceLibelle", rs.getString("piece_libelle"));

                    long pieceFournieId = rs.getLong("piece_fournie_id");
                    boolean scanned = !rs.wasNull();
                    item.put("scanStatut", scanned ? "SCANNÉ" : "EN_ATTENTE");
                    item.put("fileName", scanned ? rs.getString("nom_fichier") : "");
                    item.put("fileSizeKo", scanned ? rs.getLong("taille_bytes") / 1024 : 0L);
                    item.put("uploadedAt", scanned && rs.getTimestamp("uploaded_at") != null ? rs.getTimestamp("uploaded_at").toString() : "");
                    item.put("pieceFournie", scanned ? buildPieceFournieFromResultSet(rs, demandeId, pieceFournieId) : null);

                    liste.add(item);
                }
            }
        }

        return liste;
    }

    private PieceFournie buildPieceFournieFromResultSet(ResultSet rs, long demandeId, long pieceFournieId) throws SQLException {
        PieceFournie pieceFournie = new PieceFournie();
        pieceFournie.setId(pieceFournieId);
        pieceFournie.setDemande_id(demandeId);
        pieceFournie.setNom_fichier(rs.getString("nom_fichier"));
        pieceFournie.setTaille_bytes(rs.getLong("taille_bytes"));
        pieceFournie.setMime_type(rs.getString("mime_type"));
        pieceFournie.setUploaded_at(rs.getTimestamp("uploaded_at"));
        return pieceFournie;
    }

    public DownloadFileResponse downloadPiece(long demandeId, long pieceRefId) throws SQLException {
        PieceFournie pieceFournie = pieceFournieDao.findByDemandeAndPieceRef(demandeId, pieceRefId);
        if (pieceFournie == null) {
            throw new IllegalArgumentException("Aucun fichier trouve pour cette piece.");
        }

        Path path = Paths.get(pieceFournie.getChemin_fichier());
        if (!Files.exists(path)) {
            throw new IllegalArgumentException("Le fichier scanne est introuvable sur disque.");
        }

        try {
            byte[] content = Files.readAllBytes(path);
            String filename = pieceFournie.getNom_fichier();
            String contentType = pieceFournie.getMime_type();
            if (contentType == null || contentType.trim().isEmpty()) {
                contentType = Files.probeContentType(path);
            }
            if (contentType == null || contentType.trim().isEmpty()) {
                contentType = "application/octet-stream";
            }
            return new DownloadFileResponse(content, filename, contentType);
        } catch (IOException e) {
            throw new IllegalArgumentException("Impossible de lire le fichier scanne.", e);
        }
    }

    public String findRefDemandeById(long demandeId) throws SQLException {
        String sql = "SELECT ref_demande FROM demande WHERE id = ? LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("ref_demande");
                }
            }
        }
        return null;
    }

    public Map<String, Object> getSuiviByRefDemande(String refDemande) throws SQLException {
        if (refDemande == null || refDemande.trim().isEmpty()) {
            throw new IllegalArgumentException("Le parametre ref est obligatoire.");
        }

        String sql = "SELECT d.id AS demande_id, d.ref_demande, d.verrouille, "
            + "sd.libelle AS statut_libelle, dm.nom, dm.prenom "
            + "FROM demande d "
            + "JOIN statut_demande sd ON sd.id = d.statut_id "
            + "JOIN passeport p ON p.id = d.passeport_id "
            + "JOIN demandeur dm ON dm.id = p.demandeur_id "
            + "WHERE d.ref_demande = ? "
            + "LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, refDemande);

            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                long demandeId = rs.getLong("demande_id");
                Map<String, Object> data = new HashMap<>();
                data.put("demandeId", demandeId);
                data.put("refDemande", rs.getString("ref_demande"));
                data.put("verrouille", rs.getBoolean("verrouille"));
                data.put("statutLibelle", rs.getString("statut_libelle"));
                data.put("nom", rs.getString("nom"));
                data.put("prenom", rs.getString("prenom"));
                data.put("piecesScannees", pieceFournieDao.findAllByDemande(demandeId));
                return data;
            }
        }
    }

    private boolean isPieceAttendue(long demandeId, long pieceRefId) throws SQLException {
        String sql = "SELECT 1 FROM demande_piece WHERE demande_id = ? AND piece_id = ? AND cochee = TRUE LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            stmt.setLong(2, pieceRefId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String normalizeContentType(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.trim().toLowerCase(Locale.ROOT);
    }

    private Path buildTargetPath(long demandeId, long pieceRefId, String originalFilename, String contentType) throws SQLException {
        String configured = System.getProperty("visa.scan.upload.dir");
        File baseDir;
        if (configured != null && !configured.trim().isEmpty()) {
            baseDir = new File(configured);
        } else {
            baseDir = new File(System.getProperty("user.dir"), "upload\\scans");
        }

        if (!baseDir.exists() && !baseDir.mkdirs()) {
            throw new SQLException("Impossible de creer le dossier de stockage scan.");
        }

        String ext = resolveExtension(originalFilename, contentType);
        String safeName = "demande_" + demandeId + "_piece_" + pieceRefId + "_" + System.currentTimeMillis() + ext;
        return new File(baseDir, safeName).toPath();
    }

    private String resolveExtension(String filename, String contentType) {
        if (filename != null && filename.contains(".")) {
            String ext = filename.substring(filename.lastIndexOf('.')).toLowerCase(Locale.ROOT);
            if (".jpg".equals(ext) || ".jpeg".equals(ext) || ".png".equals(ext) || ".pdf".equals(ext)) {
                return ext;
            }
        }

        if ("image/jpeg".equals(contentType)) {
            return ".jpg";
        }
        if ("image/png".equals(contentType)) {
            return ".png";
        }
        return ".pdf";
    }

    private String extractSafeName(String filename) {
        if (filename == null || filename.trim().isEmpty()) {
            return "document";
        }

        String normalized = filename.replace("\\", "/");
        int idx = normalized.lastIndexOf('/');
        String base = idx >= 0 ? normalized.substring(idx + 1) : normalized;
        return base.trim().isEmpty() ? "document" : base;
    }

    private void writeFile(Path path, byte[] content) throws SQLException {
        try {
            Files.write(path, content, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING, StandardOpenOption.WRITE);
        } catch (IOException e) {
            throw new SQLException("Impossible d'enregistrer le fichier sur disque.", e);
        }
    }

    private void deleteFileQuietly(String path) {
        if (path == null || path.trim().isEmpty()) {
            return;
        }
        try {
            Files.deleteIfExists(Paths.get(path));
        } catch (IOException ignored) {
            // best effort
        }
    }
}
