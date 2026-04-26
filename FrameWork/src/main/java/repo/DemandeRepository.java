package repo;

import dao.DemandeDao;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import models.Demande;
import models.Passeport;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeDocument;
import models.TypeTitre;
import util.DatabaseConnection;

public class DemandeRepository implements DemandeDao {

    @Override
    public long save(Demande demande) throws SQLException {
        String sql = "INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id, created_at, updated_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW()) RETURNING id";

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
            if (demande.getVisa_date_entree() == null) {
                stmt.setNull(5, Types.DATE);
            } else {
                stmt.setDate(5, Date.valueOf(demande.getVisa_date_entree()));
            }
            stmt.setString(6, demande.getVisa_lieu_entree());
            if (demande.getVisa_date_expiration() == null) {
                stmt.setNull(7, Types.DATE);
            } else {
                stmt.setDate(7, Date.valueOf(demande.getVisa_date_expiration()));
            }
            stmt.setString(8, demande.getRef_demande());
            if (demande.getType_document() == null) {
                stmt.setNull(9, Types.BIGINT);
            } else {
                stmt.setLong(9, demande.getType_document().getId());
            }

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
        String sql = "UPDATE demande SET passeport_id = ?, type_demande_id = ?, type_titre_id = ?, statut_id = ?, visa_date_entree = ?, visa_lieu_entree = ?, visa_date_expiration = ?, updated_at = NOW() WHERE id = ?";

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
        String sql = "SELECT id, passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, created_at, updated_at FROM  demande WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return mapResultSetToDemande(rs);
            }
        }
    }

    @Override
    public Demande findBy(String column, Object value) throws SQLException {
        String sql;
        boolean useDate = false;

        switch (column.toLowerCase()) {
            case "nom":
            case "prenom":
                sql = "SELECT d.id, d.passeport_id, d.type_demande_id, d.type_titre_id, d.statut_id, d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, d.ref_demande, d.type_document_id, d.created_at, d.updated_at " +
                      "FROM demande d " +
                      "JOIN passeport p ON d.passeport_id = p.id " +
                      "JOIN demandeur dem ON p.demandeur_id = dem.id " +
                      "WHERE dem." + column.toLowerCase() + " = ? " +
                      "ORDER BY d.created_at DESC LIMIT 1";
                break;
            case "date_naissance":
                sql = "SELECT d.id, d.passeport_id, d.type_demande_id, d.type_titre_id, d.statut_id, d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, d.ref_demande, d.type_document_id, d.created_at, d.updated_at " +
                      "FROM demande d " +
                      "JOIN passeport p ON d.passeport_id = p.id " +
                      "JOIN demandeur dem ON p.demandeur_id = dem.id " +
                      "WHERE dem.date_naissance = ? " +
                      "ORDER BY d.created_at DESC LIMIT 1";
                useDate = true;
                break;
            default:
                throw new IllegalArgumentException("Recherche non supportée pour la colonne : " + column);
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (useDate) {
                if (value instanceof LocalDate) {
                    stmt.setDate(1, Date.valueOf((LocalDate) value));
                } else if (value instanceof String) {
                    stmt.setDate(1, Date.valueOf(LocalDate.parse((String) value)));
                } else {
                    throw new IllegalArgumentException("Valeur invalide pour date_naissance : " + value);
                }
            } else {
                stmt.setObject(1, value);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                return mapResultSetToDemande(rs);
            }
        }
    }

    private Demande mapResultSetToDemande(ResultSet rs) throws SQLException {
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

        if (hasColumn(rs, "ref_demande")) {
            demande.setRef_demande(rs.getString("ref_demande"));
        }

        if (hasColumn(rs, "type_document_id")) {
            long typeDocumentId = rs.getLong("type_document_id");
            if (!rs.wasNull()) {
                TypeDocument typeDocument = new TypeDocument();
                typeDocument.setId(typeDocumentId);
                demande.setType_document(typeDocument);
            }
        }

        Timestamp created = rs.getTimestamp("created_at");
        Timestamp updated = rs.getTimestamp("updated_at");
        demande.setCreated_at(created);
        demande.setUpdated_at(updated);

        return demande;
    }

    private boolean hasColumn(ResultSet rs, String columnName) throws SQLException {
        ResultSetMetaData metadata = rs.getMetaData();
        int count = metadata.getColumnCount();
        for (int i = 1; i <= count; i++) {
            if (columnName.equalsIgnoreCase(metadata.getColumnLabel(i))) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void saveDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException {
        if (pieceIds == null || pieceIds.isEmpty()) {
            return;
        }

        String sql = "INSERT INTO demande_piece (demande_id, piece_id, cochee, created_at) VALUES (?, ?, TRUE, NOW()) ON CONFLICT (demande_id, piece_id) DO UPDATE SET cochee = EXCLUDED.cochee";

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
        String deleteSql = "DELETE FROM  demande_piece WHERE demande_id = ?";
        String insertSql = "INSERT INTO  demande_piece (demande_id, piece_id, cochee, created_at) VALUES (?, ?, TRUE, NOW())";

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
