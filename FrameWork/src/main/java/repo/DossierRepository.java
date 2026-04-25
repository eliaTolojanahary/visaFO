package repo;

import dao.DossierDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import models.Dossier;
import util.DatabaseConnection;

public class DossierRepository implements DossierDao {

    @Override
    public Dossier create(Dossier dossier) throws SQLException {
        String sql = "INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme, created_at, updated_at) "
                + "VALUES (?, ?, ?, ?, NOW(), NOW()) RETURNING id, created_at, updated_at";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, dossier.getPrevious_demande_ref());
            stmt.setString(2, dossier.getNew_demande_ref());
            stmt.setString(3, dossier.getMention());
            stmt.setBoolean(4, dossier.isVisa_approuve_confirme());

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    dossier.setId(rs.getLong("id"));
                    dossier.setCreated_at(rs.getTimestamp("created_at"));
                    dossier.setUpdated_at(rs.getTimestamp("updated_at"));
                    return dossier;
                }
            }
        }

        throw new SQLException("Insertion de dossier échouée: aucun id retourné.");
    }

    @Override
    public Dossier findByDemande(long demande_id) throws SQLException {
        String sql = "SELECT d.id, d.previous_demande_ref, d.new_demande_ref, d.mention, d.visa_approuve_confirme, d.created_at, d.updated_at "
                + "FROM dossier d "
                + "JOIN dossier_demande dd ON d.id = dd.dossier_id "
                + "WHERE dd.demande_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, demande_id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToDossier(rs);
                }
            }
        }

        return null;
    }

    private Dossier mapResultSetToDossier(ResultSet rs) throws SQLException {
        Dossier dossier = new Dossier();
        dossier.setId(rs.getLong("id"));
        dossier.setPrevious_demande_ref(rs.getString("previous_demande_ref"));
        dossier.setNew_demande_ref(rs.getString("new_demande_ref"));
        dossier.setMention(rs.getString("mention"));
        dossier.setVisa_approuve_confirme(rs.getBoolean("visa_approuve_confirme"));
        dossier.setCreated_at(rs.getTimestamp("created_at"));
        dossier.setUpdated_at(rs.getTimestamp("updated_at"));
        return dossier;
    }
}