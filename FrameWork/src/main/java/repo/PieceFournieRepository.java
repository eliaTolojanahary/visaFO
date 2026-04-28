package repo;

import dao.PieceFournieDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.PieceFournie;
import models.PieceJustificative;
import util.DatabaseConnection;

public class PieceFournieRepository implements PieceFournieDao {

    @Override
    public PieceFournie create(PieceFournie piece) throws SQLException {
        String sql = "INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at) "
            + "VALUES (?, ?, ?, ?, ?, ?, NOW()) "
            + "ON CONFLICT (demande_id, piece_ref_id) DO UPDATE SET "
            + "chemin_fichier = EXCLUDED.chemin_fichier, "
            + "nom_fichier = EXCLUDED.nom_fichier, "
            + "taille_bytes = EXCLUDED.taille_bytes, "
            + "mime_type = EXCLUDED.mime_type, "
            + "uploaded_at = NOW() "
            + "RETURNING id, demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, piece.getDemande_id());
            stmt.setLong(2, piece.getPiece_ref().getId());
            stmt.setString(3, piece.getChemin_fichier());
            stmt.setString(4, piece.getNom_fichier());
            stmt.setLong(5, piece.getTaille_bytes());
            stmt.setString(6, piece.getMime_type());

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapPieceFournie(rs);
                }
            }
        }

        throw new SQLException("Insertion piece_fournie echouee.");
    }

    @Override
    public PieceFournie findByDemandeAndPieceRef(long demandeId, long pieceRefId) throws SQLException {
        String sql = "SELECT pf.id, pf.demande_id, pf.piece_ref_id, p.libelle AS piece_libelle, "
            + "pf.chemin_fichier, pf.nom_fichier, pf.taille_bytes, pf.mime_type, pf.uploaded_at "
            + "FROM piece_fournie pf "
            + "JOIN piece_justificative_ref p ON p.id = pf.piece_ref_id "
            + "WHERE pf.demande_id = ? AND pf.piece_ref_id = ? "
            + "LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            stmt.setLong(2, pieceRefId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapPieceFournie(rs);
                }
            }
        }

        return null;
    }

    @Override
    public List<PieceFournie> findAllByDemande(long demandeId) throws SQLException {
        String sql = "SELECT pf.id, pf.demande_id, pf.piece_ref_id, p.libelle AS piece_libelle, "
            + "pf.chemin_fichier, pf.nom_fichier, pf.taille_bytes, pf.mime_type, pf.uploaded_at "
            + "FROM piece_fournie pf "
            + "JOIN piece_justificative_ref p ON p.id = pf.piece_ref_id "
            + "WHERE pf.demande_id = ? "
            + "ORDER BY pf.uploaded_at DESC";

        List<PieceFournie> pieces = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    pieces.add(mapPieceFournie(rs));
                }
            }
        }

        return pieces;
    }

    @Override
    public void deleteByDemandeAndPieceRef(long demandeId, long pieceRefId) throws SQLException {
        String sql = "DELETE FROM piece_fournie WHERE demande_id = ? AND piece_ref_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            stmt.setLong(2, pieceRefId);
            stmt.executeUpdate();
        }
    }

    private PieceFournie mapPieceFournie(ResultSet rs) throws SQLException {
        PieceFournie piece = new PieceFournie();
        piece.setId(rs.getLong("id"));
        piece.setDemande_id(rs.getLong("demande_id"));

        PieceJustificative pieceRef = new PieceJustificative();
        pieceRef.setId(rs.getLong("piece_ref_id"));
        try {
            String libelle = rs.getString("piece_libelle");
            if (libelle != null) {
                pieceRef.setLibelle(libelle);
            }
        } catch (SQLException ignored) {
            // piece_libelle is optional depending on query.
        }
        piece.setPiece_ref(pieceRef);

        piece.setChemin_fichier(rs.getString("chemin_fichier"));
        piece.setNom_fichier(rs.getString("nom_fichier"));
        piece.setTaille_bytes(rs.getLong("taille_bytes"));
        piece.setMime_type(rs.getString("mime_type"));
        piece.setUploaded_at(rs.getTimestamp("uploaded_at"));
        return piece;
    }
}
