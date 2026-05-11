package services;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
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

        // TÂCHE 3: Construire l'objet Demande (minimaliste, sans validation exhaustive)
        Demande demande = buildDemandeForDuplicata(passeport, ref_demande);

        // Sauvegarder la demande via la méthode inline
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

        System.out.println("[DEBUG] Duplicata créé: ref=" + ref_demande + ", dossier=" + createdDossier.getId());
        return createdDossier;
    }
    
    /**
     * Construit l'objet Demande pour un Duplicata (minimaliste)
     * Statut = "En cours de traitement" (par TÂCHE 4 dans DemandeService)
     */
    private Demande buildDemandeForDuplicata(Passeport passeport, String ref_demande) throws SQLException {
        Demande demande = new Demande();
        demande.setPasseport(passeport);

        // Type demande = Duplicata
        TypeDemande typeDemande = getTypeDemandeByLibelle("Duplicata");
        demande.setType_demande(typeDemande);

        // Type document = Titre de residence (obligatoire pour Duplicata)
        TypeDocument typeDocument = getTypeDocumentByLibelle("Titre de residence");
        demande.setType_document(typeDocument);

        // Statut = "En cours de traitement" (TÂCHE 4 adaptée)
        StatutDemande statut = getStatutDemandeByLibelle("En cours de traitement");
        if (statut == null) {
            // Fallback si le statut n'existe pas
            statut = getStatutDemandeByLibelle("demande creee");
        }
        demande.setStatut(statut);

        demande.setRef_demande(ref_demande);
        
        return demande;
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
        // TÂCHE 2: Remplir validation métier complète
        
        // Étape 1: Valider demandeur
        validateDemandeur(demandeur);
        
        // Étape 2: Valider passeport
        validatePasseport(passeport);
        
        // Étape 3: Vérifier unicité passeport par demandeur
        verifyPasseportUnique(demandeur, passeport);
        
        // Étape 4: Si previous_demande_ref renseigné, vérifier demande existe
        if (previous_demande_ref != null && !previous_demande_ref.trim().isEmpty()) {
            verifyPreviousDemande(previous_demande_ref);
        }
    }

    /**
     * Valide les champs obligatoires du demandeur
     */
    private void validateDemandeur(Demandeur demandeur) throws IllegalArgumentException {
        if (demandeur == null) {
            throw new IllegalArgumentException("Demandeur: objet NULL");
        }
        if (demandeur.getNom() == null || demandeur.getNom().trim().isEmpty()) {
            throw new IllegalArgumentException("Demandeur: nom obligatoire");
        }
        if (demandeur.getDate_naissance() == null) {
            throw new IllegalArgumentException("Demandeur: date naissance obligatoire");
        }
        System.out.println("[DEBUG] Validation demandeur OK: " + demandeur.getNom());
    }

    /**
     * Valide les champs obligatoires du passeport et sa validité
     */
    private void validatePasseport(Passeport passeport) throws IllegalArgumentException {
        if (passeport == null) {
            throw new IllegalArgumentException("Passeport: objet NULL");
        }
        if (passeport.getNumero_passeport() == null || passeport.getNumero_passeport().trim().isEmpty()) {
            throw new IllegalArgumentException("Passeport: numéro obligatoire");
        }
        
        Object dateExpirationObj = passeport.getDate_expiration();
        if (dateExpirationObj == null) {
            throw new IllegalArgumentException("Passeport: date expiration obligatoire");
        }
        
        // Vérifier passeport non expiré (convertir en LocalDate pour comparaison)
        java.time.LocalDate dateExpiration = null;
        if (dateExpirationObj instanceof java.time.LocalDate) {
            dateExpiration = (java.time.LocalDate) dateExpirationObj;
        } else if (dateExpirationObj instanceof java.time.LocalDateTime) {
            dateExpiration = ((java.time.LocalDateTime) dateExpirationObj).toLocalDate();
        }
        
        if (dateExpiration != null && dateExpiration.isBefore(java.time.LocalDate.now())) {
            throw new IllegalArgumentException("Passeport: expiré depuis " + dateExpiration);
        }
        
        System.out.println("[DEBUG] Validation passeport OK: " + passeport.getNumero_passeport());
    }

    /**
     * Vérifie qu'un passeport n'est lié qu'à 1 demandeur maximum
     * Règle métier: un passeport ne peut pas être rattaché à 2 demandeurs différents
     */
    private void verifyPasseportUnique(Demandeur demandeur, Passeport passeport) throws SQLException {
        if (passeport.getId() <= 0) {
            return; // Nouveau passeport, pas de contrainte
        }

        String sql = "SELECT demandeur_id FROM passeport WHERE id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, passeport.getId());
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    long existingDemandeurId = rs.getLong("demandeur_id");
                    if (existingDemandeurId != demandeur.getId()) {
                        throw new SQLException("ERREUR: Ce passeport (" + passeport.getNumero_passeport() + ") est déjà lié à un autre demandeur");
                    }
                }
            }
        }
        System.out.println("[DEBUG] Unicité passeport vérifiée");
    }

    /**
     * Vérifie si la demande antécédent existe (si renseignée)
     * Log WARNING si pas trouvée (cas "antecedent non retrouvé")
     */
    private void verifyPreviousDemande(String previousDemandeRef) throws SQLException {
        String sql = "SELECT id FROM demande WHERE ref_demande = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, previousDemandeRef);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    System.out.println("[DEBUG] Demande antécédent trouvée: " + previousDemandeRef);
                } else {
                    System.out.println("[WARN] Duplicata: demande antécédent NON trouvée: " + previousDemandeRef + " (cas normal si antecedent perdu)");
                }
            }
        }
    }
}