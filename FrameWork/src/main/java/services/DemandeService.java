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
import models.Passeport;
import models.PieceJustificative;
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
        this.demandeDao = new DemandeRepository();
        this.pieceDao = new PieceJustificativeRepository();
        this.referenceDao = new ReferenceVisaRepository();
    }

    public Map<String, String> isObligatoire(Map<String, Object> formData) {
        Map<String, String> errors = new HashMap<>();

        String[] requiredFields = new String[] {
            "nom", "nom_jeune_fille", "date_naissance", "situation_famille_id", "nationalite_id",
            "adresse_madagascar", "numero_telephone", "profession",
            "numero_passeport", "date_delivrance", "date_expiration", "pays_delivrance",
            "visa_date_entree", "visa_lieu_entree", "visa_date_expiration",
            "type_demande_id", "type_titre_id"
        };

        for (String field : requiredFields) {
            String value = stringValue(formData.get(field));
            if (value == null || value.trim().isEmpty()) {
                errors.put(field, "Champ obligatoire manquant");
            }
        }

        List<Long> pieceIds = parsePieceIds(formData);
        if (pieceIds.isEmpty()) {
            errors.put("piece_ids", "Au moins une pièce justificative doit être cochée");
        }

        validateDate(formData, "date_naissance", errors);
        validateDate(formData, "date_delivrance", errors);
        validateDate(formData, "date_expiration", errors);
        validateDate(formData, "visa_date_entree", errors);
        validateDate(formData, "visa_date_expiration", errors);

        return errors;
    }

    public Demande saveDemande(Map<String, Object> formData) throws SQLException {
        Map<String, String> errors = isObligatoire(formData);
        if (!errors.isEmpty()) {
            throw new IllegalArgumentException("Validation des champs obligatoires échouée");
        }

        Demande demande = buildDemandeFromForm(formData);

        StatutDemande statut = referenceDao.findStatutByLibelle("demande creee");
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

        Demande demande = buildDemandeFromForm(formData);
        demande.setId(demandeId);

        StatutDemande statut = referenceDao.findStatutByLibelle("demande creee");
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
        List<PieceJustificative> pieces = pieceDao.findAll();

        List<PieceJustificative> piecesCommunes = pieces.stream()
            .filter(p -> p.getType_titre() == null)
            .collect(Collectors.toList());

        List<PieceJustificative> piecesSpecifiques = pieces.stream()
            .filter(p -> p.getType_titre() != null
                && p.getType_titre().getLibelle() != null
                && p.getType_titre().getLibelle().equalsIgnoreCase(typeTitreLibelle))
            .collect(Collectors.toList());

        Map<String, List<PieceJustificative>> result = new HashMap<>();
        result.put("piecesCommunes", piecesCommunes);
        result.put("piecesSpecifiques", piecesSpecifiques);
        return result;
    }

    public List<TypeTitre> getTypeTitreOptions() throws SQLException {
        return referenceDao.findAllTypeTitres();
    }

    private Demande buildDemandeFromForm(Map<String, Object> formData) throws SQLException {
        Demande demande = new Demande();

        Passeport passeport = new Passeport();
        passeport.setId(parseLongRequired(formData, "passeport_id"));
        demande.setPasseport(passeport);

        TypeDemande typeDemande = referenceDao.findTypeDemandeById(parseLongRequired(formData, "type_demande_id"));
        if (typeDemande == null) {
            throw new IllegalArgumentException("type_demande_id introuvable en base.");
        }
        demande.setType_demande(typeDemande);

        Long typeTitreId = parseLongOptional(formData, "type_titre_id");
        TypeTitre typeTitre = referenceDao.findTypeTitreById(typeTitreId);
        demande.setType_titre(typeTitre);

        demande.setVisa_date_entree(parseDateRequired(formData, "visa_date_entree"));
        demande.setVisa_lieu_entree(stringValue(formData.get("visa_lieu_entree")));
        demande.setVisa_date_expiration(parseDateRequired(formData, "visa_date_expiration"));

        return demande;
    }

    private void validateDate(Map<String, Object> formData, String field, Map<String, String> errors) {
        String raw = stringValue(formData.get(field));
        if (raw == null || raw.trim().isEmpty()) {
            return;
        }

        try {
            LocalDate.parse(raw);
        } catch (DateTimeParseException e) {
            errors.put(field, "Format de date invalide (attendu yyyy-MM-dd)");
        }
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

    private long parseLongRequired(Map<String, Object> formData, String key) {
        String raw = stringValue(formData.get(key));
        if (raw == null || raw.isEmpty()) {
            throw new IllegalArgumentException(key + " est obligatoire.");
        }

        try {
            return Long.parseLong(raw);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(key + " invalide.", e);
        }
    }

    private Long parseLongOptional(Map<String, Object> formData, String key) {
        String raw = stringValue(formData.get(key));
        if (raw == null || raw.isEmpty()) {
            return null;
        }

        try {
            return Long.valueOf(raw);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(key + " invalide.", e);
        }
    }

    private LocalDate parseDateRequired(Map<String, Object> formData, String key) {
        String raw = stringValue(formData.get(key));
        if (raw == null || raw.isEmpty()) {
            throw new IllegalArgumentException(key + " est obligatoire.");
        }

        try {
            return LocalDate.parse(raw);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Format invalide pour " + key + " (yyyy-MM-dd)", e);
        }
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
