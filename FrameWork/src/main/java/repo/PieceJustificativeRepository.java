package repo;

import dao.PieceJustificativeDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.PieceJustificative;
import models.TypeTitre;
import util.DatabaseConnection;

public class PieceJustificativeRepository implements PieceJustificativeDao {

    @Override
    public List<PieceJustificative> findAll() throws SQLException {
        System.out.println("[DEBUG REPO] findAll() PieceJustificative appel\u00e9");
        String sql = "SELECT p.id, p.libelle, p.id_type_titre, t.libelle AS type_titre_libelle FROM  piece_justificative_ref p LEFT JOIN  type_titre t ON t.id = p.id_type_titre ORDER BY p.id";
        List<PieceJustificative> pieces = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            System.out.println("[DEBUG REPO] SQL ex\u00e9cut\u00e9: " + sql);
            while (rs.next()) {
                pieces.add(mapPiece(rs));
            }
            System.out.println("[DEBUG REPO] Pi\u00e8ces justificatives charg\u00e9es: " + pieces.size());
        } catch (SQLException e) {
            System.err.println("[DEBUG REPO] ERREUR SQL: " + e.getMessage());
            throw e;
        }

        return pieces;
    }

    @Override
    public List<PieceJustificative> findByTypeTitreId(Long typeTitreId) throws SQLException {
        String sql = "SELECT p.id, p.libelle, p.id_type_titre, t.libelle AS type_titre_libelle FROM  piece_justificative_ref p LEFT JOIN  type_titre t ON t.id = p.id_type_titre WHERE (p.id_type_titre = ? OR p.id_type_titre IS NULL) ORDER BY p.id";
        List<PieceJustificative> pieces = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (typeTitreId == null) {
                stmt.setNull(1, java.sql.Types.BIGINT);
            } else {
                stmt.setLong(1, typeTitreId);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    pieces.add(mapPiece(rs));
                }
            }
        }

        return pieces;
    }

    @Override
    public PieceJustificative findById(long id) throws SQLException {
        String sql = "SELECT p.id, p.libelle, p.id_type_titre, t.libelle AS type_titre_libelle FROM  piece_justificative_ref p LEFT JOIN  type_titre t ON t.id = p.id_type_titre WHERE p.id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapPiece(rs);
                }
            }
        }

        return null;
    }

    private PieceJustificative mapPiece(ResultSet rs) throws SQLException {
        PieceJustificative piece = new PieceJustificative();
        piece.setId(rs.getLong("id"));
        piece.setLibelle(rs.getString("libelle"));

        long typeTitreId = rs.getLong("id_type_titre");
        if (!rs.wasNull()) {
            TypeTitre typeTitre = new TypeTitre();
            typeTitre.setId(typeTitreId);
            typeTitre.setLibelle(rs.getString("type_titre_libelle"));
            piece.setType_titre(typeTitre);
        }

        return piece;
    }
}
