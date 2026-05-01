package services;

import dao.DemandeDao;
import dao.PieceJustificativeDao;
import dao.ReferenceVisaDao;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import models.Demande;
import models.Nationalite;
import models.Passeport;
import models.PieceJustificative;
import models.SituationFamille;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeTitre;
import repo.DemandeRepository;
import repo.PieceJustificativeRepository;
import repo.ReferenceVisaRepository;

public class DemandeService {

    private final DemandeDao demandeDao;
    private final PieceJustificativeDao pieceDao;
    private final ReferenceVisaDao referenceDao;

    public DemandeService() {
        System.out.println("[DEBUG SERVICE] Initialisation DemandeService");
        this.demandeDao = new DemandeRepository();
        this.pieceDao = new PieceJustificativeRepository();
        this.referenceDao = new ReferenceVisaRepository();
        System.out.println("[DEBUG SERVICE] DAOs initialisés");
    }
    
    public Map<String, Object> getDemandeByRef(String ref) throws SQLException {
        return ((DemandeRepository) demandeDao).getDemandeByRef(ref); // ou ajouter la méthode dans l'interface DemandeDao
    }
    
    public Map<String, Object> getDemandeMapById(long demandeId) throws SQLException {
        return demandeDao.getDemandeMapById(demandeId);
    }
    public Map<String, String> isObligatoire(Map<String, Object> formData) {
        Map<String, String> errors = new HashMap<>();

        requireAny(formData, errors, "nom", "nom");
        requireAny(formData, errors, "nom_jeune_fille", "nom_jeune_fille", "nomJeuneFille");
        requireAny(formData, errors, "date_naissance", "date_naissance", "dateNaissance");
        requireAny(formData, errors, "situation_famille_id", "situation_famille_id", "situationFamilleId");
        requireAny(formData, errors, "nationalite_id", "nationalite_id", "nationaliteId");
        requireAny(formData, errors, "adresse_madagascar", "adresse_madagascar", "adresseMadagascar");
        requireAny(formData, errors, "numero_telephone", "numero_telephone", "numeroTelephone");
        requireAny(formData, errors, "profession", "profession");
        requireAny(formData, errors, "numero_passeport", "numero_passeport", "numeroPasseport");
        requireAny(formData, errors, "date_delivrance", "date_delivrance", "dateDelivrance");
        requireAny(formData, errors, "date_expiration", "date_expiration", "dateExpiration");
        requireAny(formData, errors, "pays_delivrance", "pays_delivrance", "paysDelivrance");
        requireAny(formData, errors, "visa_date_entree", "visa_date_entree", "visaDateEntree");
        requireAny(formData, errors, "visa_lieu_entree", "visa_lieu_entree", "visaLieuEntree");
        requireAny(formData, errors, "visa_date_expiration", "visa_date_expiration", "visaDateExpiration");
        requireAny(formData, errors, "type_demande_id", "type_demande_id", "typeDemande");

        String typeTitreRaw = stringValueAny(formData, "type_titre_id", "typeTitreId");
        String profilRaw = stringValueAny(formData, "profil");
        if ((typeTitreRaw == null || typeTitreRaw.isEmpty()) && (profilRaw == null || profilRaw.isEmpty())) {
            errors.put("type_titre_id", "Champ obligatoire manquant");
        }

        List<Long> pieceIds = parsePieceIds(formData);
        if (pieceIds.isEmpty()) {
            errors.put("piece_ids", "Au moins une pièce justificative doit être cochée");
        }

        validateDate(formData, errors, "date_naissance", "dateNaissance");
        validateDate(formData, errors, "date_delivrance", "dateDelivrance");
        validateDate(formData, errors, "date_expiration", "dateExpiration");
        validateDate(formData, errors, "visa_date_entree", "visaDateEntree");
        validateDate(formData, errors, "visa_date_expiration", "visaDateExpiration");

        return errors;
    }

    public Demande saveDemande(Map<String, Object> formData) throws SQLException {
        Map<String, String> errors = isObligatoire(formData);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Validation des champs obligatoires échouée");
        }

        Demande demande = buildDemandeFromForm(formData);

        StatutDemande statut = resolveStatusForForm(formData);
        if (statut == null) {
            statut = referenceDao.findStatutByLibelle("demande creee");
        }
        if (statut == null) {
            throw new IllegalArgumentException("Le statut 'demande creee' est introuvable en base.");
        }
        demande.setStatut(statut);

        long demandeId = demandeDao.save(demande);
        demande.setId(demandeId);

        List<Long> pieceIds = parsePieceIds(formData);
        demandeDao.saveDemandePieces(demandeId, pieceIds);

        return demande;
    }

    public Demande saveDemandeWithPassportLookup(Map<String, Object> formData) throws SQLException {
        String numeroPasseport = stringValueAny(formData, "numero_passeport", "numeroPasseport");
        if (numeroPasseport != null && !numeroPasseport.isEmpty()) {
            Long existingPassportId = demandeDao.findPasseportIdByNumero(numeroPasseport);
            if (existingPassportId != null) {
                formData.put("passeport_id", String.valueOf(existingPassportId));
            }
        }

        Map<String, String> errors = isObligatoire(formData);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Validation des champs obligatoires échouée");
        }

        Demande demande = buildDemandeFromForm(formData);
        StatutDemande statut = resolveStatusForForm(formData);
        if (statut == null) {
            statut = referenceDao.findStatutByLibelle("demande creee");
        }
        if (statut == null) {
            throw new IllegalArgumentException("Aucun statut applicable trouvé en base.");
        }
        demande.setStatut(statut);

        long demandeId = demandeDao.save(demande);
        demande.setId(demandeId);

        List<Long> pieceIds = parsePieceIds(formData);
        demandeDao.saveDemandePieces(demandeId, pieceIds);

        return demande;
    }

    private StatutDemande resolveStatusForForm(Map<String, Object> formData) throws SQLException {
        Long typeDemandeId = parseLongRequiredAny(formData, "type_demande_id", "typeDemande");
        TypeDemande typeDemande = referenceDao.findTypeDemandeById(typeDemandeId);
        if (typeDemande == null || typeDemande.getLibelle() == null) {
            return null;
        }

        String libelle = typeDemande.getLibelle().trim().toLowerCase();
        boolean visaApprouveConfirme = isTrueValue(stringValueAny(formData, "visaApprouveConfirme", "visa_approuve_confirme"));

        if (!libelle.contains("nouveau") && visaApprouveConfirme) {
            return referenceDao.findStatutByLibelle("Valide");
        }

        if (libelle.contains("visa")) {
            return referenceDao.findStatutByLibelle("Valide");
        }
        if (libelle.contains("duplicata") || libelle.contains("titre") || libelle.contains("titre de residence")) {
            return referenceDao.findStatutByLibelle("demande creee");
        }

        return referenceDao.findStatutByLibelle("demande creee");
    }

    public boolean updateDemande(Map<String, Object> formData) throws SQLException {
        String idRaw = stringValue(formData.get("demande_id"));
        if (idRaw == null || idRaw.isEmpty()) {
            throw new IllegalArgumentException("demande_id est obligatoire pour la mise à jour.");
        }

        long demandeId;
        try {
            demandeId = Long.parseLong(idRaw);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("demande_id invalide.", e);
        }

        Map<String, String> errors = isObligatoire(formData);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Validation des champs obligatoires échouée");
        }

        Demande existing = demandeDao.findById(demandeId);
        if (existing == null) {
            throw new IllegalArgumentException("Aucune demande trouvée avec l'id " + demandeId);
        }
        if (existing.isVerrouille()) {
            throw new DemandeVerrouilleeException("Cette demande est verrouillee et ne peut plus etre modifiee.");
        }

        Demande demande = buildDemandeFromForm(formData);
        demande.setId(demandeId);

        StatutDemande statut = resolveStatusForForm(formData);
        if (statut == null) {
            statut = referenceDao.findStatutByLibelle("demande creee");
        }
        if (statut != null) {
            demande.setStatut(statut);
        } else {
            demande.setStatut(existing.getStatut());
        }

        boolean updated = demandeDao.update(demande);
        if (updated) {
            demandeDao.replaceDemandePieces(demandeId, parsePieceIds(formData));
        }

        return updated;
    }

    public boolean isDemandeVerrouillee(long demandeId) throws SQLException {
        Demande demande = demandeDao.findById(demandeId);
        return demande != null && demande.isVerrouille();
    }

    public Map<String, List<PieceJustificative>> getInfoSpecifique(Long idType) throws SQLException {
        List<PieceJustificative> pieces = pieceDao.findAll();

        List<PieceJustificative> piecesCommunes = pieces.stream()
            .filter(p -> p.getType_titre() == null)
            .collect(Collectors.toList());

        List<PieceJustificative> piecesSpecifiques = pieces.stream()
            .filter(p -> p.getType_titre() != null && idType != null && p.getType_titre().getId() == idType)
            .collect(Collectors.toList());

        Map<String, List<PieceJustificative>> result = new HashMap<>();
        result.put("piecesCommunes", piecesCommunes);
        result.put("piecesSpecifiques", piecesSpecifiques);
        return result;
    }

    public Map<String, List<PieceJustificative>> getInfoSpecifiqueByLibelle(String typeTitreLibelle) throws SQLException {
        System.out.println("[DEBUG SERVICE] getInfoSpecifiqueByLibelle('" + typeTitreLibelle + "') appel\u00e9");
        List<PieceJustificative> pieces = pieceDao.findAll();
        System.out.println("[DEBUG SERVICE] Total pi\u00e8ces charg\u00e9es: " + pieces.size());

        List<PieceJustificative> piecesCommunes = pieces.stream()
            .filter(p -> p.getType_titre() == null)
            .collect(Collectors.toList());
        System.out.println("[DEBUG SERVICE] Pi\u00e8ces communes: " + piecesCommunes.size());

        List<PieceJustificative> piecesSpecifiques = pieces.stream()
            .filter(p -> p.getType_titre() != null
                && p.getType_titre().getLibelle() != null
                && p.getType_titre().getLibelle().equalsIgnoreCase(typeTitreLibelle))
            .collect(Collectors.toList());
        System.out.println("[DEBUG SERVICE] Pi\u00e8ces sp\u00e9cifiques pour " + typeTitreLibelle + ": " + piecesSpecifiques.size());

        Map<String, List<PieceJustificative>> result = new HashMap<>();
        result.put("piecesCommunes", piecesCommunes);
        result.put("piecesSpecifiques", piecesSpecifiques);
        return result;
    }

    public List<TypeTitre> getTypeTitreOptions() throws SQLException {
        return referenceDao.findAllTypeTitres();
    }

    public List<SituationFamille> getSituationFamilleOptions() throws SQLException {
        System.out.println("[DEBUG SERVICE] getSituationFamilleOptions() appelé");
        List<SituationFamille> result = referenceDao.findAllSituationsFamille();
        System.out.println("[DEBUG SERVICE] Situations familiales trouvées: " + result.size());
        return result;
    }

    public List<Nationalite> getNationaliteOptions() throws SQLException {
        System.out.println("[DEBUG SERVICE] getNationaliteOptions() appelé");
        List<Nationalite> result = referenceDao.findAllNationalites();
        System.out.println("[DEBUG SERVICE] Nationalités trouvées: " + result.size());
        return result;
    }

    public List<TypeDemande> getTypeDemandeOptions() throws SQLException {
        System.out.println("[DEBUG SERVICE] getTypeDemandeOptions() appelé");
        List<TypeDemande> result = referenceDao.findAllTypesDemande();
        System.out.println("[DEBUG SERVICE] Types de demande trouvés: " + result.size());
        return result;
    }

    public Long findLatestDemandeIdByNumeroPasseport(Map<String, Object> formData) throws SQLException {
        String numeroPasseport = stringValueAny(formData, "numero_passeport", "numeroPasseport");
        return demandeDao.findLatestDemandeIdByNumeroPasseport(numeroPasseport);
    }

    public Map<String, Object> getFormDataByDemandeId(long demandeId) throws SQLException {
        return demandeDao.getFormDataByDemandeId(demandeId);
    }

    public List<Long> getSelectedPieceIdsByDemandeId(long demandeId) throws SQLException {
        return demandeDao.getSelectedPieceIdsByDemandeId(demandeId);
    }

    public Map<String, Object> searchDemandeurEtPasseport(String nom, String prenom, String dateNaissance, String numeroPasseport) throws SQLException {
        return demandeDao.searchDemandeurEtPasseport(nom, prenom, dateNaissance, numeroPasseport);
    }

    public Map<String, Object> getLatestDemandeDashboardData() throws SQLException {
        return demandeDao.getLatestDemandeDashboardData();
    }

    public List<Map<String, Object>> getDashboardDemandesData() throws SQLException {
        return demandeDao.getDashboardDemandesData();
    }

    public Demande searchBy(String column, Object value) throws SQLException {
        return demandeDao.findBy(column, value);
    }

    private Demande buildDemandeFromForm(Map<String, Object> formData) throws SQLException {
        Demande demande = new Demande();

        Passeport passeport = new Passeport();
        passeport.setId(ensurePasseportId(formData));
        demande.setPasseport(passeport);

        TypeDemande typeDemande = referenceDao.findTypeDemandeById(parseLongRequiredAny(formData, "type_demande_id", "typeDemande"));
        if (typeDemande == null) {
            throw new IllegalArgumentException("type_demande_id introuvable en base.");
        }
        demande.setType_demande(typeDemande);

        Long typeTitreId = resolveTypeTitreId(formData);
        TypeTitre typeTitre = referenceDao.findTypeTitreById(typeTitreId);
        demande.setType_titre(typeTitre);

        demande.setVisa_date_entree(parseDateRequiredAny(formData, "visa_date_entree", "visaDateEntree"));
        demande.setVisa_lieu_entree(stringValueAny(formData, "visa_lieu_entree", "visaLieuEntree"));
        demande.setVisa_date_expiration(parseDateRequiredAny(formData, "visa_date_expiration", "visaDateExpiration"));

        return demande;
    }

    private void validateDate(Map<String, Object> formData, Map<String, String> errors, String canonicalField, String... aliases) {
        String raw = stringValueAny(formData, aliases);
        if (raw == null || raw.trim().isEmpty()) {
            return;
        }

        try {
            LocalDate.parse(raw);
        } catch (DateTimeParseException e) {
            errors.put(canonicalField, "Format de date invalide (attendu yyyy-MM-dd)");
        }
    }

    private void requireAny(Map<String, Object> formData, Map<String, String> errors, String canonicalKey, String... acceptedKeys) {
        String value = stringValueAny(formData, acceptedKeys);
        if (value == null || value.isEmpty()) {
            errors.put(canonicalKey, "Champ obligatoire manquant");
        }
    }

    private boolean isTrueValue(String rawValue) {
        if (rawValue == null) {
            return false;
        }
        String normalized = rawValue.trim().toLowerCase();
        return "true".equals(normalized)
            || "on".equals(normalized)
            || "1".equals(normalized)
            || "oui".equals(normalized)
            || "yes".equals(normalized);
    }

    private long ensurePasseportId(Map<String, Object> formData) throws SQLException {
        Long passeportId = parseLongOptionalAny(formData, "passeport_id", "passeportId");
        if (passeportId != null) {
            return passeportId;
        }

        String numeroPasseport = stringValueAny(formData, "numero_passeport", "numeroPasseport");
        Long existingPasseportId = demandeDao.findPasseportIdByNumero(numeroPasseport);
        if (existingPasseportId != null) {
            return existingPasseportId;
        }

        long demandeurId = demandeDao.insertDemandeur(formData);
        return demandeDao.insertPasseport(demandeurId, formData);
    }

    private Long resolveTypeTitreId(Map<String, Object> formData) throws SQLException {
        Long typeTitreId = parseLongOptionalAny(formData, "type_titre_id", "typeTitreId");
        if (typeTitreId != null) {
            return typeTitreId;
        }

        String profil = stringValueAny(formData, "profil");
        if (profil == null || profil.isEmpty()) {
            return null;
        }

        String expectedLibelle;
        if ("investisseur".equalsIgnoreCase(profil)) {
            expectedLibelle = "Investisseur";
        } else if ("travailleur".equalsIgnoreCase(profil)) {
            expectedLibelle = "Travailleur";
        } else {
            return null;
        }

        List<TypeTitre> titres = referenceDao.findAllTypeTitres();
        for (TypeTitre titre : titres) {
            if (titre.getLibelle() != null && titre.getLibelle().equalsIgnoreCase(expectedLibelle)) {
                return titre.getId();
            }
        }

        return null;
    }

    private List<Long> parsePieceIds(Map<String, Object> formData) {
        List<Long> ids = new ArrayList<>();

        Object raw = formData.get("piece_ids");
        if (raw == null) {
            raw = formData.get("piece_id");
        }
        if (raw == null) {
            return ids;
        }

        if (raw instanceof String[] values) {
            for (String value : values) {
                tryAddLong(ids, value);
            }
            return ids;
        }

        if (raw instanceof String single) {
            if (single.contains(",")) {
                String[] values = single.split(",");
                for (String value : values) {
                    tryAddLong(ids, value);
                }
            } else {
                tryAddLong(ids, single);
            }
            return ids;
        }

        return ids;
    }

    private void tryAddLong(List<Long> ids, String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return;
        }
        try {
            ids.add(Long.valueOf(raw.trim()));
        } catch (NumberFormatException ignored) {
            // Skip invalid checkbox values.
        }
    }

    private long parseLongRequiredAny(Map<String, Object> formData, String... keys) {
        String raw = stringValueAny(formData, keys);
        if (raw == null || raw.isEmpty()) {
            throw new IllegalArgumentException(keys[0] + " est obligatoire.");
        }

        try {
            return Long.parseLong(raw);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(keys[0] + " invalide.", e);
        }
    }

    private Long parseLongOptionalAny(Map<String, Object> formData, String... keys) {
        String raw = stringValueAny(formData, keys);
        if (raw == null || raw.isEmpty()) {
            return null;
        }

        try {
            return Long.valueOf(raw);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(keys[0] + " invalide.", e);
        }
    }

    private LocalDate parseDateRequiredAny(Map<String, Object> formData, String... keys) {
        String raw = stringValueAny(formData, keys);
        if (raw == null || raw.isEmpty()) {
            throw new IllegalArgumentException(keys[0] + " est obligatoire.");
        }

        try {
            return LocalDate.parse(raw);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Format invalide pour " + keys[0] + " (yyyy-MM-dd)", e);
        }
    }

    private String stringValueAny(Map<String, Object> formData, String... keys) {
        for (String key : keys) {
            String value = stringValue(formData.get(key));
            if (value != null && !value.isEmpty()) {
                return value;
            }
        }
        return null;
    }

    private String stringValue(Object raw) {
        if (raw == null) {
            return null;
        }
        if (raw instanceof String[] values) {
            if (values.length == 0) {
                return null;
            }
            return values[0];
        }
        return String.valueOf(raw).trim();
    }
}
