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
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
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
    private static final long MAX_SIGNATURE_SIZE = 1L * 1024L * 1024L;
    private static final String BASE64_PNG_PREFIX = "data:image/png;base64,";
    private static final String LIBELLE_SIGNATURE = "Signature numerique";
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

    // =========================================================================
    // SIGNATURE CANVAS
    // =========================================================================

    /**
     * Sauvegarde une signature capturée depuis un canvas HTML (data URL PNG base64).
     *
     * @param base64DataUrl  la data URL complète : "data:image/png;base64,<payload>"
     * @param demandeId      identifiant de la demande
     * @param dossierId      identifiant du dossier (utilisé pour l'arborescence disque)
     * @return l'objet {@link PieceFournie} persisté
     * @throws IllegalArgumentException si le format ou la taille sont invalides
     * @throws SQLException             en cas d'erreur base de données ou disque
     */
    public PieceFournie sauvegarderSignatureCanvas(String base64DataUrl, Long demandeId, Long dossierId)
            throws SQLException {

        // 1. Validation du format base64
        if (base64DataUrl == null || !base64DataUrl.startsWith(BASE64_PNG_PREFIX)) {
            throw new IllegalArgumentException(
                "Format de signature invalide. Une image PNG encodee en base64 est attendue.");
        }

        String payload = base64DataUrl.substring(BASE64_PNG_PREFIX.length()).trim();
        if (payload.isEmpty()) {
            throw new IllegalArgumentException("Le contenu de la signature est vide.");
        }

        byte[] pngBytes;
        try {
            pngBytes = Base64.getDecoder().decode(payload);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Encodage base64 invalide : " + e.getMessage(), e);
        }

        // 2. Validation de la taille (≤ 1 Mo)
        if (pngBytes.length > MAX_SIGNATURE_SIZE) {
            throw new IllegalArgumentException(
                "La signature depasse la taille maximale autorisee (1 Mo).");
        }

        // 3. Vérification de l'existence de la demande
        Demande demande = demandeDao.findById(demandeId);
        if (demande == null) {
            throw new IllegalArgumentException("Demande introuvable : " + demandeId);
        }
        if (demande.isVerrouille()) {
            throw new DemandeVerrouilleeException(
                "Le dossier est verrouille : aucune modification n'est autorisee.");
        }

        // 4a. Résoudre dossierId si non fourni (0 ou null)
        long resolvedDossierId = (dossierId != null && dossierId > 0)
            ? dossierId
            : findDossierIdByDemande(demandeId);

        // 4b. Résoudre l'id réel de "Signature numérique" directement en SQL
        long pieceRefId = findPieceRefIdByLibelle(LIBELLE_SIGNATURE);
        if (pieceRefId < 0) {
            throw new IllegalArgumentException(
                "La reference de piece 'Signature numerique' est introuvable en base. "
                + "Verifiez que sprint5.sql a bien ete execute.");
        }

        // 5. Suppression de l'ancienne signature si elle existe déjà
        PieceFournie existante = pieceFournieDao.findByDemandeAndPieceRef(demandeId, pieceRefId);
        if (existante != null) {
            deleteFileQuietly(existante.getChemin_fichier());
        }

        // 6. Construction du chemin et écriture sur disque
        Path targetPath = buildSignaturePath(resolvedDossierId, demandeId, pngBytes);
        writeFile(targetPath, pngBytes);

        // 7. Construction de PieceFournie avec pieceRefId résolu dynamiquement
        PieceJustificative pieceRef = pieceJustificativeDao.findById(pieceRefId);
        PieceFournie pieceFournie = new PieceFournie();
        pieceFournie.setDemande_id(demandeId);
        pieceFournie.setPiece_ref(pieceRef);
        pieceFournie.setChemin_fichier(targetPath.toAbsolutePath().toString());
        pieceFournie.setNom_fichier(targetPath.getFileName().toString());
        pieceFournie.setTaille_bytes(pngBytes.length);
        pieceFournie.setMime_type("image/png");

        try {
            PieceFournie saved = pieceFournieDao.create(pieceFournie);
            refreshScanStatusIfComplete(demandeId);
            return saved;
        } catch (SQLException e) {
            deleteFileQuietly(targetPath.toString());
            throw e;
        }
    }

    /**
     * Met à jour le statut du dossier si toutes les pièces sont présentes.
     * Appel silencieux : les erreurs sont loggées mais ne remontent pas.
     */
    private void refreshScanStatusIfComplete(long demandeId) {
        try {
            if (isDemandeComplete(demandeId)) {
                // On peut déclencher ici toute logique métier supplémentaire
                // (ex: notification, mise à jour de statut intermédiaire).
                // Pour l'instant on se contente de la vérification passive.
            }
        } catch (SQLException ignored) {
            // best effort
        }
    }


    /**
     * Trouve le dossier_id lié à une demande via dossier_demande.
     * Retourne demandeId comme fallback si aucun dossier n'est trouvé.
     */
    private long findDossierIdByDemande(long demandeId) throws SQLException {
        String sql = "SELECT dossier_id FROM dossier_demande WHERE demande_id = ? LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("dossier_id");
                }
            }
        }
        return demandeId; // fallback
    }

    /**
     * Retourne l'id de piece_justificative_ref correspondant au libelle,
     * ou -1 si introuvable. Pas de dépendance au model PieceJustificative.
     */
    private long findPieceRefIdByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id FROM piece_justificative_ref WHERE LOWER(libelle) = LOWER(?) LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, libelle);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }
        return -1L;
    }

    /**
     * Construit le chemin cible pour la signature :
     * {@code <base>/uploads/pieces/signatures/<dossierId>/<dossierId>_sig_<ts>_<hash>.png}
     */
    private Path buildSignaturePath(long dossierId, Long demandeId, byte[] content) throws SQLException {
        String configured = System.getProperty("visa.scan.upload.dir");
        File baseDir;
        if (configured != null && !configured.trim().isEmpty()) {
            baseDir = new File(configured, "pieces/signatures/" + dossierId);
        } else {
            baseDir = new File(System.getProperty("user.dir"),
                "upload/scans/pieces/signatures/" + dossierId);
        }

        if (!baseDir.exists() && !baseDir.mkdirs()) {
            throw new SQLException("Impossible de creer le repertoire de signatures : " + baseDir.getAbsolutePath());
        }

        String hash = computeShortHash(content);
        String filename = dossierId + "_sig_" + System.currentTimeMillis() + "_" + hash + ".png";
        return new File(baseDir, filename).toPath();
    }

    /** Calcule un hash SHA-256 tronqué à 8 caractères pour nommer le fichier. */
    private String computeShortHash(byte[] data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(data);
            // Java 17+: HexFormat; sinon utiliser un fallback manuel
            return HexFormat.of().formatHex(hashBytes).substring(0, 8);
        } catch (Exception e) {
            return Long.toHexString(System.nanoTime()).substring(0, 8);
        }
    }

    // =========================================================================
    // MÉTHODES EXISTANTES (inchangées)
    // =========================================================================

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
            + "LEFT JOIN piece_fournie pf ON pf.demande_id = dp.demande_id AND pf.piece_ref_id = dp.piece_id "
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