package repo;

import dao.DemandeDao;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.List;
import models.Demande;
import models.Passeport;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeTitre;
import util.DatabaseConnection;

public class DemandeRepository implements DemandeDao {

    @Override
    public long save(Demande demande) throws SQLException {
        String sql = "INSERT INTO visa.demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, created_at, updated_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW()) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, demande.getPasseport().getId());
            stmt.setLong(2, demande.getType_demande().getId());
            if (demande.getType_titre() == null) {
                stmt.setNull(3, Types.BIGINT);
            } else {
                stmt.setLong(3, demande.getType_titre().getId());
            }
            stmt.setLong(4, demande.getStatut().getId());
            stmt.setDate(5, Date.valueOf(demande.getVisa_date_entree()));
            stmt.setString(6, demande.getVisa_lieu_entree());
            stmt.setDate(7, Date.valueOf(demande.getVisa_date_expiration()));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("Insertion de demande échouée: aucun id retourné.");
    }

    @Override
    public boolean update(Demande demande) throws SQLException {
        String sql = "UPDATE visa.demande SET passeport_id = ?, type_demande_id = ?, type_titre_id = ?, statut_id = ?, visa_date_entree = ?, visa_lieu_entree = ?, visa_date_expiration = ?, updated_at = NOW() WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, demande.getPasseport().getId());
            stmt.setLong(2, demande.getType_demande().getId());
            if (demande.getType_titre() == null) {
                stmt.setNull(3, Types.BIGINT);
            } else {
                stmt.setLong(3, demande.getType_titre().getId());
            }
            stmt.setLong(4, demande.getStatut().getId());
            stmt.setDate(5, Date.valueOf(demande.getVisa_date_entree()));
            stmt.setString(6, demande.getVisa_lieu_entree());
            stmt.setDate(7, Date.valueOf(demande.getVisa_date_expiration()));
            stmt.setLong(8, demande.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    @Override
    public Demande findById(long id) throws SQLException {
        String sql = "SELECT id, passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, created_at, updated_at FROM visa.demande WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Demande demande = new Demande();
                demande.setId(rs.getLong("id"));

                Passeport passeport = new Passeport();
                passeport.setId(rs.getLong("passeport_id"));
                demande.setPasseport(passeport);

                TypeDemande typeDemande = new TypeDemande();
                typeDemande.setId(rs.getLong("type_demande_id"));
                demande.setType_demande(typeDemande);

                long typeTitreId = rs.getLong("type_titre_id");
                if (!rs.wasNull()) {
                    TypeTitre typeTitre = new TypeTitre();
                    typeTitre.setId(typeTitreId);
                    demande.setType_titre(typeTitre);
                }

                StatutDemande statut = new StatutDemande();
                statut.setId(rs.getLong("statut_id"));
                demande.setStatut(statut);

                Date entree = rs.getDate("visa_date_entree");
                if (entree != null) {
                    demande.setVisa_date_entree(entree.toLocalDate());
                }
                demande.setVisa_lieu_entree(rs.getString("visa_lieu_entree"));

                Date expiration = rs.getDate("visa_date_expiration");
                if (expiration != null) {
                    demande.setVisa_date_expiration(expiration.toLocalDate());
                }

                Timestamp created = rs.getTimestamp("created_at");
                Timestamp updated = rs.getTimestamp("updated_at");
                demande.setCreated_at(created);
                demande.setUpdated_at(updated);

                return demande;
            }
        }
    }

    @Override
    public void saveDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException {
        if (pieceIds == null || pieceIds.isEmpty()) {
            return;
        }

        String sql = "INSERT INTO visa.demande_piece (demande_id, piece_id, cochee, created_at) VALUES (?, ?, TRUE, NOW()) ON CONFLICT (demande_id, piece_id) DO UPDATE SET cochee = EXCLUDED.cochee";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (Long pieceId : pieceIds) {
                stmt.setLong(1, demandeId);
                stmt.setLong(2, pieceId);
                stmt.addBatch();
            }
            stmt.executeBatch();
        }
    }

    @Override
    public void replaceDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException {
        String deleteSql = "DELETE FROM visa.demande_piece WHERE demande_id = ?";
        String insertSql = "INSERT INTO visa.demande_piece (demande_id, piece_id, cochee, created_at) VALUES (?, ?, TRUE, NOW())";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement deleteStmt = conn.prepareStatement(deleteSql)) {
                    deleteStmt.setLong(1, demandeId);
                    deleteStmt.executeUpdate();
                }

                if (pieceIds != null && !pieceIds.isEmpty()) {
                    try (PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {
                        for (Long pieceId : pieceIds) {
                            insertStmt.setLong(1, demandeId);
                            insertStmt.setLong(2, pieceId);
                            insertStmt.addBatch();
                        }
                        insertStmt.executeBatch();
                    }
                }

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
