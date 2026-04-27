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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
            case "nom", "prenom" -> sql = "SELECT d.id, d.passeport_id, d.type_demande_id, d.type_titre_id, d.statut_id, d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, d.ref_demande, d.type_document_id, d.created_at, d.updated_at " +
                "FROM demande d " +
                "JOIN passeport p ON d.passeport_id = p.id " +
                "JOIN demandeur dem ON p.demandeur_id = dem.id " +
                "WHERE dem." + column.toLowerCase() + " = ? " +
                "ORDER BY d.created_at DESC LIMIT 1";
            case "date_naissance" -> {
                sql = "SELECT d.id, d.passeport_id, d.type_demande_id, d.type_titre_id, d.statut_id, d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, d.ref_demande, d.type_document_id, d.created_at, d.updated_at " +
                    "FROM demande d " +
                    "JOIN passeport p ON d.passeport_id = p.id " +
                    "JOIN demandeur dem ON p.demandeur_id = dem.id " +
                    "WHERE dem.date_naissance = ? " +
                    "ORDER BY d.created_at DESC LIMIT 1";
                useDate = true;
            }
            default -> throw new IllegalArgumentException("Recherche non supportée pour la colonne : " + column);
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            if (useDate) {
                if (value instanceof LocalDate localDate) {
                    stmt.setDate(1, Date.valueOf(localDate));
                } else if (value instanceof String text) {
                    stmt.setDate(1, Date.valueOf(LocalDate.parse(text)));
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

    @Override
    public Long findLatestDemandeIdByNumeroPasseport(String numeroPasseport) throws SQLException {
        if (numeroPasseport == null || numeroPasseport.trim().isEmpty()) {
            return null;
        }

        String sql = "SELECT d.id FROM demande d JOIN passeport p ON p.id = d.passeport_id WHERE p.numero_passeport = ? ORDER BY d.updated_at DESC, d.id DESC LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, numeroPasseport.trim());
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        return null;
    }

    @Override
    public Map<String, Object> getFormDataByDemandeId(long demandeId) throws SQLException {
        String sql = "SELECT d.id AS demande_id, d.passeport_id, d.type_demande_id, d.type_titre_id, "
            + "d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, "
            + "dm.nom, dm.prenom, dm.nom_jeune_fille, dm.date_naissance, dm.situation_famille_id, "
            + "dm.nationalite_id, dm.adresse_madagascar, dm.numero_telephone, dm.email, dm.profession, "
            + "p.numero_passeport, p.date_delivrance, p.date_expiration, p.pays_delivrance, "
            + "tt.libelle AS type_titre_libelle "
            + "FROM demande d "
            + "JOIN passeport p ON p.id = d.passeport_id "
            + "JOIN demandeur dm ON dm.id = p.demandeur_id "
            + "LEFT JOIN type_titre tt ON tt.id = d.type_titre_id "
            + "WHERE d.id = ? LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Map<String, Object> formData = new HashMap<>();
                formData.put("demande_id", String.valueOf(rs.getLong("demande_id")));
                formData.put("passeport_id", String.valueOf(rs.getLong("passeport_id")));
                formData.put("typeDemande", String.valueOf(rs.getLong("type_demande_id")));

                long typeTitreId = rs.getLong("type_titre_id");
                if (!rs.wasNull()) {
                    formData.put("typeTitreId", String.valueOf(typeTitreId));
                }

                putDateString(formData, "visaDateEntree", rs.getDate("visa_date_entree"));
                formData.put("visaLieuEntree", rs.getString("visa_lieu_entree"));
                putDateString(formData, "visaDateExpiration", rs.getDate("visa_date_expiration"));

                formData.put("nom", rs.getString("nom"));
                formData.put("prenom", rs.getString("prenom"));
                formData.put("nomJeuneFille", rs.getString("nom_jeune_fille"));
                putDateString(formData, "dateNaissance", rs.getDate("date_naissance"));
                formData.put("situationFamilleId", String.valueOf(rs.getLong("situation_famille_id")));
                formData.put("nationaliteId", String.valueOf(rs.getLong("nationalite_id")));
                formData.put("adresseMadagascar", rs.getString("adresse_madagascar"));
                formData.put("numeroTelephone", rs.getString("numero_telephone"));
                formData.put("email", rs.getString("email"));
                formData.put("profession", rs.getString("profession"));

                formData.put("numeroPasseport", rs.getString("numero_passeport"));
                putDateString(formData, "dateDelivrance", rs.getDate("date_delivrance"));
                putDateString(formData, "dateExpiration", rs.getDate("date_expiration"));
                formData.put("paysDelivrance", rs.getString("pays_delivrance"));

                String typeTitreLibelle = rs.getString("type_titre_libelle");
                if (typeTitreLibelle != null) {
                    if ("investisseur".equalsIgnoreCase(typeTitreLibelle)) {
                        formData.put("profil", "investisseur");
                    } else if ("travailleur".equalsIgnoreCase(typeTitreLibelle)) {
                        formData.put("profil", "travailleur");
                    }
                }

                return formData;
            }
        }
    }

    @Override
    public List<Long> getSelectedPieceIdsByDemandeId(long demandeId) throws SQLException {
        List<Long> selected = new ArrayList<>();
        String sql = "SELECT piece_id FROM demande_piece WHERE demande_id = ? AND cochee = TRUE";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    selected.add(rs.getLong("piece_id"));
                }
            }
        }

        return selected;
    }

    @Override
    public Map<String, Object> searchDemandeurEtPasseport(
            String nom,
            String prenom,
            String dateNaissance,
            String numeroPasseport
    ) throws SQLException {
    
        StringBuilder sql = new StringBuilder(
            "SELECT d.nom, d.prenom, d.date_naissance, d.adresse_madagascar, d.numero_telephone, d.email, d.profession, " +
            "n.libelle as nationalite, " +
            "p.numero_passeport, p.date_delivrance, p.date_expiration, p.pays_delivrance " +
            "FROM demandeur d " +
            "JOIN passeport p ON p.demandeur_id = d.id " +
            "LEFT JOIN nationalite n ON d.nationalite_id = n.id " +
            "WHERE 1=1 "
        );
    
        List<Object> params = new ArrayList<>();
    
        // Recherche flexible + case insensitive
        if (numeroPasseport != null && !numeroPasseport.trim().isEmpty()) {
            sql.append("AND LOWER(p.numero_passeport) LIKE LOWER(?) ");
            params.add("%" + numeroPasseport.trim() + "%");
        }
    
        if (nom != null && !nom.trim().isEmpty()) {
            sql.append("AND LOWER(COALESCE(d.nom, '')) LIKE LOWER(?) ");
            params.add("%" + nom.trim() + "%");
        }
    
        if (prenom != null && !prenom.trim().isEmpty()) {
            sql.append("AND LOWER(COALESCE(d.prenom, '')) LIKE LOWER(?) ");
            params.add("%" + prenom.trim() + "%");
        }
    
        if (dateNaissance != null && !dateNaissance.trim().isEmpty()) {
            sql.append("AND d.date_naissance = ? ");
            params.add(Date.valueOf(dateNaissance.trim()));
        }
    
        // IMPORTANT : 1 seul résultat
        sql.append("ORDER BY p.updated_at DESC LIMIT 1");
    
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
    
            for (int i = 0; i < params.size(); i++) {
                stmt.setObject(i + 1, params.get(i));
            }
    
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
    
                Map<String, Object> result = new HashMap<>();
    
                result.put("nom", rs.getString("nom"));
                result.put("prenom", rs.getString("prenom"));
                result.put("dateNaissance", rs.getDate("date_naissance") != null ? rs.getDate("date_naissance").toString() : "");
                result.put("nationalite", rs.getString("nationalite"));
                result.put("adresseMadagascar", rs.getString("adresse_madagascar"));
                result.put("numeroTelephone", rs.getString("numero_telephone"));
                result.put("email", rs.getString("email"));
                result.put("profession", rs.getString("profession"));
                result.put("numeroPasseport", rs.getString("numero_passeport"));
                result.put("dateDelivrance", rs.getDate("date_delivrance") != null ? rs.getDate("date_delivrance").toString() : "");
                result.put("dateExpiration", rs.getDate("date_expiration") != null ? rs.getDate("date_expiration").toString() : "");
                result.put("paysDelivrance", rs.getString("pays_delivrance"));
    
                return result;
            }
        }
    }

    @Override
    public Map<String, Object> getLatestDemandeDashboardData() throws SQLException {
        String sql = "SELECT d.id AS demande_id, d.passeport_id, d.type_demande_id, d.type_titre_id, d.statut_id, "
            + "d.visa_date_entree, d.visa_lieu_entree, d.visa_date_expiration, d.created_at AS demande_created_at, d.updated_at AS demande_updated_at, "
            + "dm.nom, dm.prenom, dm.profession, dm.numero_telephone, dm.email, "
            + "p.numero_passeport, tt.libelle AS type_titre_libelle, td.libelle AS type_demande_libelle, sd.libelle AS statut_libelle "
            + "FROM demande d "
            + "JOIN passeport p ON p.id = d.passeport_id "
            + "JOIN demandeur dm ON dm.id = p.demandeur_id "
            + "JOIN type_demande td ON td.id = d.type_demande_id "
            + "LEFT JOIN type_titre tt ON tt.id = d.type_titre_id "
            + "JOIN statut_demande sd ON sd.id = d.statut_id "
            + "ORDER BY d.updated_at DESC, d.id DESC LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            if (!rs.next()) {
                return null;
            }

            Map<String, Object> dashboard = new HashMap<>();
            dashboard.put("demande_id", String.valueOf(rs.getLong("demande_id")));
            dashboard.put("passeport_id", String.valueOf(rs.getLong("passeport_id")));
            dashboard.put("typeDemande", String.valueOf(rs.getLong("type_demande_id")));
            dashboard.put("typeDemandeLibelle", rs.getString("type_demande_libelle"));
            dashboard.put("typeTitreLibelle", rs.getString("type_titre_libelle"));
            dashboard.put("statutLibelle", rs.getString("statut_libelle"));
            dashboard.put("visaDateEntree", rs.getDate("visa_date_entree") != null ? rs.getDate("visa_date_entree").toLocalDate().toString() : null);
            dashboard.put("visaLieuEntree", rs.getString("visa_lieu_entree"));
            dashboard.put("visaDateExpiration", rs.getDate("visa_date_expiration") != null ? rs.getDate("visa_date_expiration").toLocalDate().toString() : null);
            dashboard.put("nom", rs.getString("nom"));
            dashboard.put("prenom", rs.getString("prenom"));
            dashboard.put("profession", rs.getString("profession"));
            dashboard.put("numeroTelephone", rs.getString("numero_telephone"));
            dashboard.put("email", rs.getString("email"));
            dashboard.put("numeroPasseport", rs.getString("numero_passeport"));
            dashboard.put("createdAt", rs.getTimestamp("demande_created_at"));
            dashboard.put("updatedAt", rs.getTimestamp("demande_updated_at"));
            return dashboard;
        }
    }

    @Override
    public List<Map<String, Object>> getDashboardDemandesData() throws SQLException {
        String sql = "SELECT d.id AS demande_id, dm.nom, dm.prenom, td.libelle AS type_demande_libelle, "
            + "COALESCE(tt.libelle, '-') AS type_titre_libelle, sd.libelle AS statut_libelle, d.updated_at "
            + "FROM demande d "
            + "JOIN passeport p ON p.id = d.passeport_id "
            + "JOIN demandeur dm ON dm.id = p.demandeur_id "
            + "JOIN type_demande td ON td.id = d.type_demande_id "
            + "LEFT JOIN type_titre tt ON tt.id = d.type_titre_id "
            + "JOIN statut_demande sd ON sd.id = d.statut_id "
            + "ORDER BY d.updated_at DESC, d.id DESC LIMIT 30";

        List<Map<String, Object>> demandes = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("demande_id", String.valueOf(rs.getLong("demande_id")));
                row.put("nom", rs.getString("nom"));
                row.put("prenom", rs.getString("prenom"));
                row.put("typeDemandeLibelle", rs.getString("type_demande_libelle"));
                row.put("typeTitreLibelle", rs.getString("type_titre_libelle"));
                row.put("statutLibelle", rs.getString("statut_libelle"));
                row.put("updatedAt", rs.getTimestamp("updated_at"));
                demandes.add(row);
            }
        }

        return demandes;
    }

    @Override
    public Long findPasseportIdByNumero(String numeroPasseport) throws SQLException {
        if (numeroPasseport == null || numeroPasseport.trim().isEmpty()) {
            return null;
        }

        String sql = "SELECT id FROM passeport WHERE numero_passeport = ? LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, numeroPasseport.trim());
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        return null;
    }

    @Override
    public long insertDemandeur(Map<String, Object> formData) throws SQLException {
        String sql = "INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW()) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, firstValue(formData, "nom"));
            stmt.setString(2, firstValue(formData, "prenom"));
            stmt.setString(3, firstValue(formData, "nom_jeune_fille", "nomJeuneFille"));
            stmt.setDate(4, Date.valueOf(LocalDate.parse(firstValue(formData, "date_naissance", "dateNaissance"))));
            stmt.setLong(5, Long.parseLong(firstValue(formData, "situation_famille_id", "situationFamilleId")));
            stmt.setLong(6, Long.parseLong(firstValue(formData, "nationalite_id", "nationaliteId")));
            stmt.setString(7, firstValue(formData, "adresse_madagascar", "adresseMadagascar"));
            stmt.setString(8, firstValue(formData, "numero_telephone", "numeroTelephone"));

            String email = firstValue(formData, "email");
            if (email == null || email.isEmpty()) {
                stmt.setNull(9, Types.VARCHAR);
            } else {
                stmt.setString(9, email);
            }

            stmt.setString(10, firstValue(formData, "profession"));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("Insertion demandeur echouee: aucun id retourne.");
    }

    @Override
    public long insertPasseport(long demandeurId, Map<String, Object> formData) throws SQLException {
        String sql = "INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance, created_at, updated_at) VALUES (?, ?, ?, ?, ?, NOW(), NOW()) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, demandeurId);
            stmt.setString(2, firstValue(formData, "numero_passeport", "numeroPasseport"));
            stmt.setDate(3, Date.valueOf(LocalDate.parse(firstValue(formData, "date_delivrance", "dateDelivrance"))));
            stmt.setDate(4, Date.valueOf(LocalDate.parse(firstValue(formData, "date_expiration", "dateExpiration"))));
            stmt.setString(5, firstValue(formData, "pays_delivrance", "paysDelivrance"));

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("Insertion passeport echouee: aucun id retourne.");
    }

    private void putDateString(Map<String, Object> target, String key, Date date) {
        if (date != null) {
            target.put(key, date.toLocalDate().toString());
        }
    }

    private String firstValue(Map<String, Object> formData, String... keys) {
        for (String key : keys) {
            Object value = formData.get(key);
            if (value == null) {
                continue;
            }
            String text = String.valueOf(value).trim();
            if (!text.isEmpty()) {
                return text;
            }
        }
        return null;
    }
}
