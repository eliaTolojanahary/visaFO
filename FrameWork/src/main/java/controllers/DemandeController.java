package controllers;

import annotation.Api;
import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import models.Demande;
import models.Nationalite;
import models.PieceJustificative;
import models.SituationFamille;
import models.TypeDemande;
import models.TypeTitre;
import modelview.ModelView;
import services.DemandeService;
import services.DemandeVerrouilleeException;
import services.QrCodeService;

@ClasseAnnotation("")
public class DemandeController {

    private final DemandeService demandeService = new DemandeService();
    private final QrCodeService qrCodeService = new QrCodeService();

    @MethodeAnnotation("/form/search")
    @PostMapping
    @Api
    public Map<String, Object> search(Map<String, Object> formData) {
        Map<String, Object> response = new HashMap<>();
        try {
            String nom = formData.get("nom") != null ? formData.get("nom").toString() : null;
            String prenom = formData.get("prenom") != null ? formData.get("prenom").toString() : null;
            String dateNaissance = formData.get("dateNaissance") != null ? formData.get("dateNaissance").toString() : null;
            String numeroPasseport = formData.get("numeroPasseport") != null ? formData.get("numeroPasseport").toString() : null;

            Map<String, Object> result = demandeService.searchDemandeurEtPasseport(nom, prenom, dateNaissance, numeroPasseport);
            response.put("found", result != null);
            response.put("message", result != null
                ? "Resultat trouve dans la base de donnees."
                : "Aucun demandeur trouve avec ces criteres.");
            if (result != null) {
                response.put("data", result);
            }
        } catch (SQLException e) {
            response.put("found", false);
            response.put("message", "Recherche indisponible pour le moment.");
        }
        return response;
    }

    /**
     * Convertit une liste de PieceJustificative en List<Map<String, Object>>
     * pour utilisation en JSP
     */
    private List<Map<String, Object>> convertPiecesJustificativesToMaps(List<PieceJustificative> pieces) {
        List<Map<String, Object>> result = new ArrayList<>();
        if (pieces != null) {
            for (PieceJustificative piece : pieces) {
                Map<String, Object> pieceMap = new HashMap<>();
                pieceMap.put("id", piece.getId());
                pieceMap.put("libelle", piece.getLibelle());
                pieceMap.put("scanStatut", "EN_ATTENTE");
                pieceMap.put("fileName", "");
                result.add(pieceMap);
            }
        }
        return result;
    }

    /**
     * Prépare les pièces justificatives selon le profil et le type de demande
     * Retourne une liste combinée (communes + spécifiques) pour affichage
     */
    private List<Map<String, Object>> preparePiecesForDisplay(String profil, String typeDemande) throws SQLException {
        List<Map<String, Object>> allPieces = new ArrayList<>();
        
        // Toujours afficher les pièces communes
        Map<String, List<PieceJustificative>> investisseur = demandeService.getInfoSpecifiqueByLibelle("Investisseur");
        List<PieceJustificative> piecesCommunes = investisseur.get("piecesCommunes");
        
        if (piecesCommunes != null) {
            allPieces.addAll(convertPiecesJustificativesToMaps(piecesCommunes));
        }
        
        // Ajouter les pièces spécifiques selon le profil
        if ("investisseur".equalsIgnoreCase(profil)) {
            Map<String, List<PieceJustificative>> investisseurData = demandeService.getInfoSpecifiqueByLibelle("Investisseur");
            List<PieceJustificative> piecesInvestisseur = investisseurData.get("piecesSpecifiques");
            if (piecesInvestisseur != null) {
                allPieces.addAll(convertPiecesJustificativesToMaps(piecesInvestisseur));
            }
        } else if ("travailleur".equalsIgnoreCase(profil)) {
            Map<String, List<PieceJustificative>> travailleurData = demandeService.getInfoSpecifiqueByLibelle("Travailleur");
            List<PieceJustificative> piecesTravailleur = travailleurData.get("piecesSpecifiques");
            if (piecesTravailleur != null) {
                allPieces.addAll(convertPiecesJustificativesToMaps(piecesTravailleur));
            }
        }
        
        return allPieces;
    }

    // CORRIGÉ: Mapping complet incluant le préfixe de la classe
    @MethodeAnnotation("/form")  
    @GetMapping
    public ModelView getForm(){
        System.out.println("[DEBUG CONTROLLER] getForm() appelé");
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
        mv.addData("mode", "CREATION");
        try {
            System.out.println("[DEBUG CONTROLLER] Chargement des données de référence...");
            Map<String, List<PieceJustificative>> investisseur = demandeService.getInfoSpecifiqueByLibelle("Investisseur");
            Map<String, List<PieceJustificative>> travailleur = demandeService.getInfoSpecifiqueByLibelle("Travailleur");
            System.out.println("[DEBUG CONTROLLER] Pièces Investisseur: " + (investisseur.get("piecesCommunes") != null ? investisseur.get("piecesCommunes").size() : 0));
            System.out.println("[DEBUG CONTROLLER] Pièces Travailleur: " + (travailleur.get("piecesSpecifiques") != null ? travailleur.get("piecesSpecifiques").size() : 0));
            
            List<TypeDemande> types = demandeService.getTypeDemandeOptions();
            System.out.println("[DEBUG CONTROLLER] Types de demande trouvés: " + types.size());
            mv.addData("typesDemandeOptions", types);
            List<TypeTitre> titres = demandeService.getTypeTitreOptions();
            System.out.println("[DEBUG CONTROLLER] Types de titre trouvés: " + titres.size());
            mv.addData("typeTitreOptions", titres);
            
            List<SituationFamille> situations = demandeService.getSituationFamilleOptions();
            System.out.println("[DEBUG CONTROLLER] Situations familiales trouvées: " + situations.size());
            mv.addData("situationsFamille", situations);
            
            List<Nationalite> nats = demandeService.getNationaliteOptions();
            System.out.println("[DEBUG CONTROLLER] Nationalités trouvées: " + nats.size());
            mv.addData("nationalites", nats);
            
            // Envoyer les pièces par catégorie AUSSI (pour les scripts JS qui en auraient besoin)
            mv.addData("piecesCommunes", investisseur.get("piecesCommunes"));
            mv.addData("piecesInvestisseur", investisseur.get("piecesSpecifiques"));
            mv.addData("piecesTravailleur", travailleur.get("piecesSpecifiques"));
            
            // [NEW] Préparer les pièces pour la vue initiale (mode création)
            // Au chargement initial, afficher les pièces communes
            List<Map<String, Object>> piecesInitiales = convertPiecesJustificativesToMaps(investisseur.get("piecesCommunes"));
            mv.addData("listePiecesAttendues", piecesInitiales);
            
            System.out.println("[DEBUG CONTROLLER] Données chargées avec succès");
        } catch (SQLException e) {
            System.err.println("[DEBUG CONTROLLER] ERREUR: " + e.getMessage());
            mv.addData("error", "Erreur de chargement du formulaire: " + e.getMessage());
        }
        return mv;
    }

    // CORRIGÉ: Redirection vers le dashboard
    @MethodeAnnotation("/")  
    @GetMapping
    public ModelView redirectToForm() {
        System.out.println("[DEBUG CONTROLLER] redirectToForm() appelé");
        ModelView mv = new ModelView("redirect:/dashboard");  
        return mv;
    }

    private void rechargeFormData(ModelView mv) throws SQLException {
        Map<String, List<PieceJustificative>> investisseur = demandeService.getInfoSpecifiqueByLibelle("Investisseur");
        Map<String, List<PieceJustificative>> travailleur = demandeService.getInfoSpecifiqueByLibelle("Travailleur");
        
        List<TypeDemande> types = demandeService.getTypeDemandeOptions();
        mv.addData("typesDemandeOptions", types);
        List<TypeTitre> titres = demandeService.getTypeTitreOptions();
        mv.addData("typeTitreOptions", titres);
        
        List<SituationFamille> situations = demandeService.getSituationFamilleOptions();
        mv.addData("situationsFamille", situations);
        
        List<Nationalite> nats = demandeService.getNationaliteOptions();
        mv.addData("nationalites", nats);
        
        mv.addData("piecesCommunes", investisseur.get("piecesCommunes"));
        mv.addData("piecesInvestisseur", investisseur.get("piecesSpecifiques"));
        mv.addData("piecesTravailleur", travailleur.get("piecesSpecifiques"));
        
        // [NEW] Préparer les pièces initiales aussi ici
        List<Map<String, Object>> piecesInitiales = convertPiecesJustificativesToMaps(investisseur.get("piecesCommunes"));
        mv.addData("listePiecesAttendues", piecesInitiales);
    }

    // CORRIGÉ: Mapping pour l'erreur
    @MethodeAnnotation("/form/error")
    @GetMapping
    public ModelView error(){
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
        mv.addData("mode", "CREATION");
        mv.addData("error", "Des champs obligatoires sont manquants ou invalides.");
        return mv;
    }

    @MethodeAnnotation("/dashboard")
    @GetMapping
    public ModelView dashboard(Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/resultDemande.jsp");
        try {
            rechargeFormData(mv);
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
            mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());

            String success = queryParams != null && queryParams.get("success") != null
                ? String.valueOf(queryParams.get("success"))
                : null;
            String action = queryParams != null && queryParams.get("action") != null
                ? String.valueOf(queryParams.get("action"))
                : null;
            String message = queryParams != null && queryParams.get("message") != null
                ? String.valueOf(queryParams.get("message"))
                : null;
            String highlightId = queryParams != null && queryParams.get("highlightId") != null
                ? String.valueOf(queryParams.get("highlightId"))
                : null;

            if ("1".equals(success)) {
                mv.addData("success", true);
                mv.addData("action", action);
                mv.addData("message", message);
            }

            if (highlightId != null && !highlightId.isEmpty()) {
                mv.addData("highlightDemandeId", highlightId);
            }
        } catch (SQLException e) {
            mv.addData("error", "Erreur de chargement du tableau de bord: " + e.getMessage());
        }
        return mv;
    }

    private String dashboardRedirectUrl(String action, long highlightId, String message) {
        String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8);
        return "redirect:/dashboard?success=1&action=" + action + "&highlightId=" + highlightId + "&message=" + encodedMessage;
    }

    // CORRIGÉ: Enregistrement demande
@MethodeAnnotation("/form/save")
@PostMapping
public ModelView save(Map<String, Object> formData) {
    ModelView mv = new ModelView("/resultDemande.jsp");

    try {
        Long existingDemandeId = demandeService.findLatestDemandeIdByNumeroPasseport(formData);

        if (existingDemandeId != null) {
            formData.put("demande_id", String.valueOf(existingDemandeId));
            boolean updated = demandeService.updateDemande(formData);
            //String refDemande = demandeService.getRefDemande(existingDemandeId);
            // Générer QR code sur update
            Demande existing = demandeService.findById(existingDemandeId);
            String refDemande = existing.getRef_demande();
            genererQrCodeSilencieux(refDemande);

            String msg = updated
                ? "Une demande existe deja pour ce passeport. Elle a ete mise a jour."
                : "Aucune demande existante n a pu etre mise a jour.";
            return new ModelView(dashboardRedirectUrl("update", existingDemandeId, msg));
        }

        // Nouveau save
        Demande demande = demandeService.saveDemande(formData);

        // Générer QR code sur create
        genererQrCodeSilencieux(demande.getRef_demande());

        return new ModelView(dashboardRedirectUrl(
            "create", demande.getId(), "Demande enregistree avec succes."
        ));

    } catch (SQLException e) {
        mv.setView("/nouvelleDemande.jsp");
        mv.addData("mode", "CREATION");
        mv.addData("success", false);
        mv.addData("error", "Erreur base de donnees: " + e.getMessage());
        mv.addData("formData", formData);
        try { rechargeFormData(mv); } catch (SQLException ex) {
            System.err.println("[DEBUG] rechargeFormData: " + ex.getMessage());
        }
    } catch (DemandeVerrouilleeException e) {
        mv.setView("/resultDemande.jsp");
        mv.addData("success", false);
        mv.addData("error", e.getMessage());
        try {
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
            mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());
        } catch (SQLException ex) {
            mv.addData("error", e.getMessage());
        }
    } catch (IllegalArgumentException e) {
        mv.setView("/nouvelleDemande.jsp");
        mv.addData("mode", "CREATION");
        mv.addData("success", false);
        mv.addData("error", e.getMessage());
        mv.addData("validationErrors", demandeService.isObligatoire(formData));
        mv.addData("formData", formData);
        try { rechargeFormData(mv); } catch (SQLException ex) {
            System.err.println("[DEBUG] rechargeFormData: " + ex.getMessage());
        }
    }
    return mv;
}

// Helper : ne jamais crasher pour un QR
private void genererQrCodeSilencieux(String ref) {
    if (ref == null || ref.isBlank()) return;
    try {
        qrCodeService.genererQrCode(ref);
        System.out.println("[QR] Généré pour : " + ref);
    } catch (Exception e) {
        System.err.println("[QR] Erreur génération : " + e.getMessage());
    }
}

    @MethodeAnnotation("/form/edit")
    @PostMapping
    public ModelView edit(Map<String, Object> formData){
        ModelView mv = new ModelView("/nouvelleDemande.jsp");

        try {
            String idRaw = formData.get("id") != null
                ? String.valueOf(formData.get("id"))
                : String.valueOf(formData.get("demande_id"));
            if (idRaw == null || idRaw.trim().isEmpty() || "null".equalsIgnoreCase(idRaw.trim())) {
                throw new IllegalArgumentException("id de demande manquant pour le mode modification.");
            }

            long demandeId;
            try {
                demandeId = Long.parseLong(idRaw.trim());
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("id de demande invalide pour le mode modification.", e);
            }

            Map<String, Object> existingFormData = demandeService.getFormDataByDemandeId(demandeId);
            if (existingFormData == null || existingFormData.isEmpty()) {
                throw new IllegalArgumentException("Aucune demande trouvee pour l'id " + demandeId + ".");
            }

            boolean verrouille = Boolean.TRUE.equals(existingFormData.get("verrouille"));
            if (verrouille) {
                mv.setView("/resultDemande.jsp");
                mv.addData("success", false);
                mv.addData("error", "Cette demande est verrouillee et ne peut plus etre modifiee.");
                mv.addData("dashboardMode", true);
                mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
                mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());
                return mv;
            }

            rechargeFormData(mv);
            mv.addData("formData", existingFormData);
            mv.addData("selectedPieceIds", demandeService.getSelectedPieceIdsByDemandeId(demandeId));
            mv.addData("mode", "UPDATE");
            mv.addData("editMode", true);
            mv.addData("message", "Mode modification active.");
        } catch (SQLException e) {
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("mode", "UPDATE");
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        } catch (DemandeVerrouilleeException e) {
            mv.setView("/resultDemande.jsp");
            mv.addData("success", false);
            mv.addData("error", e.getMessage());
            try {
                mv.addData("dashboardMode", true);
                mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
                mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());
            } catch (SQLException ex) {
                mv.addData("error", e.getMessage());
            }
        } catch (IllegalArgumentException e) {
            mv.addData("error", e.getMessage());
            mv.addData("mode", "UPDATE");
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        }

        return mv;
    }

    // CORRIGÉ: Mise à jour demande existante
    @MethodeAnnotation("/form/update")
    @PostMapping
    public ModelView update(Map<String, Object> formData){
        ModelView mv = new ModelView("/resultDemande.jsp");

        try {
            boolean updated = demandeService.updateDemande(formData);
            if (updated) {
                String idRaw = formData.get("demande_id") != null ? String.valueOf(formData.get("demande_id")) : "0";
                long demandeId = Long.parseLong(idRaw);

                Demande existing = demandeService.findById(demandeId);
    genererQrCodeSilencieux(existing != null ? existing.getRef_demande() : null);
                return new ModelView(dashboardRedirectUrl("update", demandeId, "Demande mise a jour avec succes."));
            }

            mv.addData("success", false);
            mv.addData("error", "Aucune demande mise a jour.");
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
            mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());
        } catch (SQLException e) {
            mv.setView("/nouvelleDemande.jsp");
            mv.addData("mode", "UPDATE");
            mv.addData("success", false);
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("formData", formData);
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        } catch (DemandeVerrouilleeException e) {
            mv.setView("/resultDemande.jsp");
            mv.addData("success", false);
            mv.addData("error", e.getMessage());
            try {
                mv.addData("dashboardMode", true);
                mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
                mv.addData("dashboardDemandes", demandeService.getDashboardDemandesData());
            } catch (SQLException ex) {
                mv.addData("error", e.getMessage());
            }
        } catch (IllegalArgumentException e) {
            mv.setView("/nouvelleDemande.jsp");
            mv.addData("mode", "UPDATE");
            mv.addData("success", false);
            mv.addData("error", e.getMessage());
            mv.addData("validationErrors", demandeService.isObligatoire(formData));
            mv.addData("formData", formData);
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        }
        return mv;
    }
    
}