package repo;

import dao.DossierDemandeDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import models.DossierDemande;
import util.DatabaseConnection;

public class DossierDemandeRepository implements DossierDemandeDao {

    private void ensureScanColumnsExist(Connection conn) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
            "ALTER TABLE dossier_demande "
                + "ADD COLUMN IF NOT EXISTS scan_termine BOOLEAN DEFAULT FALSE, "
                + "ADD COLUMN IF NOT EXISTS date_scan_complete TIMESTAMP"
        )) {
            stmt.execute();
        }
    }

    @Override
    public DossierDemande findDossierDemande(Long dossierId, Long demandeId) throws SQLException {
        String sql = "SELECT id, dossier_id, demande_id, scan_termine, date_scan_complete, created_at "
            + "FROM dossier_demande WHERE dossier_id = ? AND demande_id = ? LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureScanColumnsExist(conn);
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setLong(1, dossierId);
                stmt.setLong(2, demandeId);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        return null;
                    }

                    DossierDemande dossierDemande = new DossierDemande();
                    dossierDemande.setId(rs.getLong("id"));
                    dossierDemande.setDossierId(rs.getLong("dossier_id"));
                    dossierDemande.setDemandeId(rs.getLong("demande_id"));
                    dossierDemande.setScanTermine(rs.getBoolean("scan_termine"));
                    dossierDemande.setDateScanComplete(rs.getTimestamp("date_scan_complete"));
                    dossierDemande.setCreatedAt(rs.getTimestamp("created_at"));
                    return dossierDemande;
                }
            }
        }
    }

    @Override
    public void updateDossierDemandeScanTermine(long dossierDemandeId) throws SQLException {
        String sql = "UPDATE dossier_demande SET scan_termine = TRUE, date_scan_complete = NOW() WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureScanColumnsExist(conn);
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setLong(1, dossierDemandeId);
                if (stmt.executeUpdate() == 0) {
                    throw new SQLException("Aucune liaison dossier_demande mise a jour pour l'id " + dossierDemandeId);
                }
            }
        }
    }
}
