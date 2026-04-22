package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.SQLException;
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

@ClasseAnnotation("")
public class DemandeController {

    private final DemandeService demandeService = new DemandeService();

    // CORRIGÉ: Mapping complet incluant le préfixe de la classe
    @MethodeAnnotation("/form")  
    @GetMapping
    public ModelView getForm(){
        System.out.println("[DEBUG CONTROLLER] getForm() appelé");
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
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
            
            mv.addData("piecesCommunes", investisseur.get("piecesCommunes"));
            mv.addData("piecesInvestisseur", investisseur.get("piecesSpecifiques"));
            mv.addData("piecesTravailleur", travailleur.get("piecesSpecifiques"));
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
    }

    // CORRIGÉ: Mapping pour l'erreur
    @MethodeAnnotation("/form/error")
    @GetMapping
    public ModelView error(){
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
        mv.addData("error", "Des champs obligatoires sont manquants ou invalides.");
        return mv;
    }

    @MethodeAnnotation("/dashboard")
    @GetMapping
    public ModelView dashboard() {
        ModelView mv = new ModelView("/resultDemande.jsp");
        try {
            rechargeFormData(mv);
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
        } catch (SQLException e) {
            mv.addData("error", "Erreur de chargement du tableau de bord: " + e.getMessage());
        }
        return mv;
    }

    // CORRIGÉ: Enregistrement demande
    @MethodeAnnotation("/form/save")
    @PostMapping
    public ModelView save(Map<String, Object> formData){
        ModelView mv = new ModelView("/resultDemande.jsp");

        try {
            Long existingDemandeId = demandeService.findLatestDemandeIdByNumeroPasseport(formData);
            if (existingDemandeId != null) {
                formData.put("demande_id", String.valueOf(existingDemandeId));
                boolean updated = demandeService.updateDemande(formData);
                mv.addData("success", updated);
                mv.addData("action", "update");
                mv.addData("message", updated
                    ? "Une demande existe deja pour ce numero de passeport. Elle a ete mise a jour."
                    : "Aucune demande existante n'a pu etre mise a jour.");
                mv.addData("dashboardMode", true);
                mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
                return mv;
            }

            Demande demande = demandeService.saveDemande(formData);
            mv.addData("success", true);
            mv.addData("demande", demande);
            mv.addData("message", "Demande enregistrée avec le statut 'demande creee'.");
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
        } catch (SQLException e) {
            mv.setView("/nouvelleDemande.jsp");
            mv.addData("success", false);
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("formData", formData);
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        } catch (IllegalArgumentException e) {
            mv.setView("/nouvelleDemande.jsp");
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

            rechargeFormData(mv);
            mv.addData("formData", existingFormData);
            mv.addData("selectedPieceIds", demandeService.getSelectedPieceIdsByDemandeId(demandeId));
            mv.addData("editMode", true);
            mv.addData("message", "Mode modification active.");
        } catch (SQLException e) {
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        } catch (IllegalArgumentException e) {
            mv.addData("error", e.getMessage());
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
            mv.addData("success", updated);
            mv.addData("message", updated ? "Demande mise à jour avec succès." : "Aucune demande mise à jour.");
            mv.addData("action", "update");
            mv.addData("dashboardMode", true);
            mv.addData("latestDemande", demandeService.getLatestDemandeDashboardData());
        } catch (SQLException e) {
            mv.setView("/nouvelleDemande.jsp");
            mv.addData("success", false);
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("formData", formData);
            try {
                rechargeFormData(mv);
            } catch (SQLException ex) {
                System.err.println("[DEBUG CONTROLLER] ERREUR rechargeFormData: " + ex.getMessage());
            }
        } catch (IllegalArgumentException e) {
            mv.setView("/nouvelleDemande.jsp");
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
