package services;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import dao.DossierDao;
import models.Demande;
import models.Demandeur;
import models.Dossier;
import models.Passeport;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeDocument;
import repo.DossierRepository;
import util.DatabaseConnection;

public class DossierService {

    private final DossierDao dossierDao;

    public DossierService() {
        this.dossierDao = new DossierRepository();
    }

    public Dossier ouvrirDossierDuplicata(Demandeur demandeur, Passeport passeport, String previous_demande_ref) throws SQLException {
        // Validation des règles métier
        validateBusinessRules(demandeur, passeport, previous_demande_ref);

        // Générer la référence de demande
        String ref_demande = generateRefDemande();

        // Créer la demande
        Demande demande = new Demande();
        demande.setPasseport(passeport);

        // Type demande = Duplicata
        TypeDemande typeDemande = getTypeDemandeByLibelle("Duplicata");
        demande.setType_demande(typeDemande);

        // Type document = Titre de residence (obligatoire pour Duplicata)
        TypeDocument typeDocument = getTypeDocumentByLibelle("Titre de residence");
        demande.setType_document(typeDocument);

        // Statut = En cours de traitement
        StatutDemande statut = getStatutDemandeByLibelle("En cours de traitement");
        demande.setStatut(statut);

        demande.setRef_demande(ref_demande);

        // Sauvegarder la demande
        long demandeId = saveDemande(demande);

        // Créer le dossier
        Dossier dossier = new Dossier();
        dossier.setPrevious_demande_ref(previous_demande_ref);
        if (previous_demande_ref != null && !previous_demande_ref.trim().isEmpty()) {
            dossier.setNew_demande_ref(ref_demande);
        }
        dossier.setMention("Duplicata — antecedent non retrouve");
        dossier.setVisa_approuve_confirme(true);

        Dossier createdDossier = dossierDao.create(dossier);

        // Insérer dans dossier_demande
        insertDossierDemande(createdDossier.getId(), demandeId);

        return createdDossier;
    }

    public void attacherDemande(long dossier_id, long demande_id) throws SQLException {
        // Vérifier si pas déjà présent
        if (!isDemandeAttached(dossier_id, demande_id)) {
            insertDossierDemande(dossier_id, demande_id);
        }
    }

    private String generateRefDemande() {
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");
        return now.format(formatter) + "-DUP";
    }

    private long saveDemande(Demande demande) throws SQLException {
        // This should be moved to DemandeService, but for now inline
        String sql = "INSERT INTO demande (passeport_id, type_demande_id, statut_id, ref_demande, type_document_id, created_at, updated_at) "
                + "VALUES (?, ?, ?, ?, ?, NOW(), NOW()) RETURNING id";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, demande.getPasseport().getId());
            stmt.setLong(2, demande.getType_demande().getId());
            stmt.setLong(3, demande.getStatut().getId());
            stmt.setString(4, demande.getRef_demande());
            stmt.setLong(5, demande.getType_document().getId());

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("Insertion de demande échouée.");
    }

    private void insertDossierDemande(long dossierId, long demandeId) throws SQLException {
        String sql = "INSERT INTO dossier_demande (dossier_id, demande_id) VALUES (?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, dossierId);
            stmt.setLong(2, demandeId);
            stmt.executeUpdate();
        }
    }

    private boolean isDemandeAttached(long dossierId, long demandeId) throws SQLException {
        String sql = "SELECT 1 FROM dossier_demande WHERE dossier_id = ? AND demande_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, dossierId);
            stmt.setLong(2, demandeId);

            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    private TypeDemande getTypeDemandeByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id, libelle FROM type_demande WHERE libelle = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, libelle);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    TypeDemande td = new TypeDemande();
                    td.setId(rs.getLong("id"));
                    td.setLibelle(rs.getString("libelle"));
                    return td;
                }
            }
        }
        throw new SQLException("TypeDemande not found: " + libelle);
    }

    private TypeDocument getTypeDocumentByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id, libelle FROM type_document WHERE libelle = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, libelle);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    TypeDocument td = new TypeDocument();
                    td.setId(rs.getLong("id"));
                    td.setLibelle(rs.getString("libelle"));
                    return td;
                }
            }
        }
        throw new SQLException("TypeDocument not found: " + libelle);
    }

    private StatutDemande getStatutDemandeByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id, libelle FROM statut_demande WHERE libelle = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, libelle);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    StatutDemande sd = new StatutDemande();
                    sd.setId(rs.getLong("id"));
                    sd.setLibelle(rs.getString("libelle"));
                    return sd;
                }
            }
        }
        throw new SQLException("StatutDemande not found: " + libelle);
    }

    private void validateBusinessRules(Demandeur demandeur, Passeport passeport, String previous_demande_ref) throws SQLException {
        // Règle: previous_demande_ref renseigne => new_demande_ref obligatoire (vérifié dans la méthode)
        if (previous_demande_ref != null && !previous_demande_ref.trim().isEmpty()) {
            // Sera vérifié lors de la création du dossier
        }

        // Règle: un passeport ne peut pas être rattaché à deux demandeurs différents
        if (passeport.getId() > 0) {
            String sql = "SELECT demandeur_id FROM passeport WHERE id = ?";
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setLong(1, passeport.getId());
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        long existingDemandeurId = rs.getLong("demandeur_id");
                        if (existingDemandeurId != demandeur.getId()) {
                            throw new SQLException("Le passeport est déjà rattaché à un autre demandeur");
                        }
                    }
                }
            }
        }
    }
}