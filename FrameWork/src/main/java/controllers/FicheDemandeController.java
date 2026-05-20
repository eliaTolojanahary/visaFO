package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.RequestParam;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import models.DossierDemande;
import models.Nationalite;
import models.PieceFournie;
import models.SituationFamille;
import models.TypeDocument;
import modelview.ModelView;
import repo.ReferenceVisaRepository;
import services.DemandeService;
import services.QrCodeService;
import services.ScanService;

@ClasseAnnotation("/demande")
public class FicheDemandeController {

    private final DemandeService demandeService = new DemandeService();
    private final ScanService scanService = new ScanService();
    private final QrCodeService qrCodeService = new QrCodeService();
    private final ReferenceVisaRepository referenceVisaRepository = new ReferenceVisaRepository();
    
    @MethodeAnnotation("/{id}/fiche")
    @GetMapping
    public ModelView ficheDemande(@RequestParam("id") long demandeId) {
        ModelView mv = new ModelView("/ficheDemande.jsp");

        try {
            Map<String, Object> demandeData = demandeService.getFormDataByDemandeId(demandeId);
            Map<String, Object> scanInfo = scanService.getDemandeScanInfo(demandeId);

            if (demandeData == null || scanInfo == null) {
                mv.addData("error", "Demande introuvable.");
                return mv;
            }

            long dossierId = demandeService.findById(demandeId) != null
                ? dossierServiceId(demandeId)
                : 0L;
            DossierDemande dossierDemande = null;
            if (dossierId > 0) {
                try {
                    dossierDemande = loadDossierDemandeSafely(dossierId, demandeId);
                } catch (SQLException ignored) {
                    dossierDemande = null;
                }
            }

            String refDemande = stringValue(scanInfo.get("refDemande"));
            if (refDemande != null && !refDemande.trim().isEmpty()) {
                try {
                    qrCodeService.genererQrCode(refDemande);
                } catch (Exception ignored) {
                    // best effort
                }
            }

            Map<String, Object> demande = buildDemandeModel(demandeId, dossierId, demandeData, scanInfo, dossierDemande);
            List<PieceFournie> piecesFournies = scanService.getPiecesFourniesByDemande(demandeId);
            long photoRefId = scanService.getPhotoIdentiteRefId();
            long signatureRefId = scanService.getSignatureNumeriqueRefId();

            mv.addData("demande", demande);
            mv.addData("piecesFournies", piecesFournies);
            mv.addData("photoIdentiteRefId", photoRefId);
            mv.addData("signatureNumeriqueRefId", signatureRefId);
            mv.addData("demandeComplete", scanService.verifierScanComplet(demandeId));
            mv.addData("qrCodeWebUrl", refDemande != null && !refDemande.trim().isEmpty()
                ? qrCodeService.getQrCodeWebUrl(refDemande)
                : null);
            mv.addData("dossierId", dossierId);
            mv.addData("demandeId", demandeId);
        } catch (SQLException e) {
            mv.addData("error", "Erreur lors du chargement de la fiche: " + e.getMessage());
        }

        return mv;
    }

    private long dossierServiceId(long demandeId) throws SQLException {
        return demandeService.findById(demandeId) != null
            ? new services.DossierService().getDossieridByDemande(demandeId)
            : 0L;
    }

    private DossierDemande loadDossierDemandeSafely(long dossierId, long demandeId) throws SQLException {
        try {
            return new repo.DossierDemandeRepository().findDossierDemande(dossierId, demandeId);
        } catch (SQLException e) {
            if (isMissingScanColumnsError(e)) {
                return null;
            }
            throw e;
        }
    }

    private boolean isMissingScanColumnsError(SQLException exception) {
        String message = exception.getMessage();
        return message != null && message.toLowerCase().contains("scan_termine");
    }

    private Map<String, Object> buildDemandeModel(long demandeId, long dossierId, Map<String, Object> demandeData,
                                                  Map<String, Object> scanInfo, DossierDemande dossierDemande) throws SQLException {
        Map<String, Object> demande = new HashMap<>();
        demande.put("id", demandeId);
        demande.put("refDemande", valueOrEmpty(demandeData.get("ref_demande"), scanInfo.get("refDemande")));
        demande.put("verrouille", Boolean.TRUE.equals(demandeData.get("verrouille")));

        Map<String, Object> statut = new HashMap<>();
        statut.put("libelle", valueOrEmpty(scanInfo.get("statutLibelle"), demandeData.get("statutLibelle")));
        demande.put("statut", statut);

        Map<String, Object> dossier = new HashMap<>();
        dossier.put("id", dossierId);
        dossier.put("scanTermine", dossierDemande != null && dossierDemande.isScanTermine());
        dossier.put("dateScanComplete", dossierDemande != null ? dossierDemande.getDateScanComplete() : null);
        demande.put("dossier", dossier);

        Map<String, Object> demandeur = new HashMap<>();
        demandeur.put("nom", demandeData.get("nom"));
        demandeur.put("prenom", demandeData.get("prenom"));
        demandeur.put("nomJeuneFille", demandeData.get("nom_jeune_fille"));
        demandeur.put("dateNaissance", demandeData.get("dateNaissance"));
        demandeur.put("profession", demandeData.get("profession"));
        demandeur.put("adresseMadagascar", demandeData.get("adresseMadagascar"));
        demandeur.put("numeroTelephone", demandeData.get("numeroTelephone"));
        demandeur.put("email", demandeData.get("email"));

        Map<String, Object> situationFamille = new HashMap<>();
        situationFamille.put("libelle", lookupSituationLibelle(demandeData.get("situation_famille_id")));
        demandeur.put("situationFamille", situationFamille);

        Map<String, Object> nationalite = new HashMap<>();
        nationalite.put("libelle", lookupNationaliteLibelle(demandeData.get("nationalite_id")));
        demandeur.put("nationalite", nationalite);
        demande.put("demandeur", demandeur);

        Map<String, Object> passeport = new HashMap<>();
        passeport.put("numeroPasseport", demandeData.get("numeroPasseport"));
        passeport.put("paysDelivrance", demandeData.get("paysDelivrance"));
        passeport.put("dateDelivrance", demandeData.get("dateDelivrance"));
        passeport.put("dateExpiration", demandeData.get("dateExpiration"));
        demande.put("passeport", passeport);

        Map<String, Object> typeDemande = new HashMap<>();
        typeDemande.put("libelle", demandeData.get("typeDemandeLibelle"));
        demande.put("typeDemande", typeDemande);

        Map<String, Object> typeDocument = new HashMap<>();
        String typeDocumentLibelle = lookupTypeDocumentLibelle(demandeData.get("type_document_id"));
        if (typeDocumentLibelle == null || typeDocumentLibelle.trim().isEmpty()) {
            typeDocumentLibelle = valueOrEmpty(demandeData.get("typeTitreLibelle"), demandeData.get("type_titre_libelle"));
        }
        typeDocument.put("libelle", typeDocumentLibelle);
        demande.put("typeDocument", typeDocument);

        return demande;
    }

    private String lookupSituationLibelle(Object idRaw) throws SQLException {
        Long id = toLong(idRaw);
        if (id == null) {
            return null;
        }
        for (SituationFamille situation : demandeService.getSituationFamilleOptions()) {
            if (situation.getId() == id) {
                return situation.getLibelle();
            }
        }
        return null;
    }

    private String lookupNationaliteLibelle(Object idRaw) throws SQLException {
        Long id = toLong(idRaw);
        if (id == null) {
            return null;
        }
        for (Nationalite nationalite : demandeService.getNationaliteOptions()) {
            if (nationalite.getId() == id) {
                return nationalite.getLibelle();
            }
        }
        return null;
    }

    private String lookupTypeDocumentLibelle(Object idRaw) throws SQLException {
        Long id = toLong(idRaw);
        if (id == null) {
            return null;
        }
        TypeDocument typeDocument = referenceVisaRepository.findTypeDocumentById(id);
        return typeDocument != null ? typeDocument.getLibelle() : null;
    }

    private Long toLong(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Long.valueOf(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String valueOrEmpty(Object primary, Object fallback) {
        String value = stringValue(primary);
        if (value != null && !value.trim().isEmpty()) {
            return value;
        }
        return stringValue(fallback);
    }

    private String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}