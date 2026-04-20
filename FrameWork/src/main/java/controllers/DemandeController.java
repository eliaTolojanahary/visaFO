package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import models.Demande;
import models.PieceJustificative;
import modelview.ModelView;
import services.DemandeService;

@ClasseAnnotation("/visa")
public class DemandeController {

    private final DemandeService demandeService = new DemandeService();

    // Acces formulaire
    @MethodeAnnotation("/visa/form")
    @GetMapping
    public ModelView getForm(){
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
        try {
            Map<String, List<PieceJustificative>> investisseur = demandeService.getInfoSpecifiqueByLibelle("Investisseur");
            Map<String, List<PieceJustificative>> travailleur = demandeService.getInfoSpecifiqueByLibelle("Travailleur");

            mv.addData("typeTitreOptions", demandeService.getTypeTitreOptions());
            mv.addData("piecesCommunes", investisseur.get("piecesCommunes"));
            mv.addData("piecesInvestisseur", investisseur.get("piecesSpecifiques"));
            mv.addData("piecesTravailleur", travailleur.get("piecesSpecifiques"));
        } catch (SQLException e) {
            mv.setView("/visaFormError.jsp");
            mv.addData("error", "Erreur de chargement du formulaire: " + e.getMessage());
        }
        return mv;
    }

    // Soumission formulaire (validation des obligatoires)
    @MethodeAnnotation("/visa/form")
    @PostMapping
    public ModelView submitForm(Map<String, Object> formData){
        ModelView mv = new ModelView("/nouvelleDemande.jsp");
        Map<String, String> errors = demandeService.isObligatoire(formData);

        if (!errors.isEmpty()) {
            mv.setView("/visaFormError.jsp");
            mv.addData("validationErrors", errors);
            mv.addData("formData", formData);
            return mv;
        }

        mv.addData("validationOk", true);
        mv.addData("message", "Validation réussie. Vous pouvez enregistrer la demande.");
        mv.addData("formData", formData);
        return mv;
    }

    // Retour erreur validation
    @MethodeAnnotation("/visa/form/error")
    @GetMapping
    public ModelView error(){
        ModelView mv = new ModelView("/visaFormError.jsp");
        mv.addData("error", "Des champs obligatoires sont manquants ou invalides.");
        return mv;
    }

    // Enregistrement demande
    @MethodeAnnotation("/visa/form/save")
    @PostMapping
    public ModelView save(Map<String, Object> formData){
        ModelView mv = new ModelView("/resultDemande.jsp");

        try {
            Demande demande = demandeService.saveDemande(formData);
            mv.addData("success", true);
            mv.addData("demande", demande);
            mv.addData("message", "Demande enregistrée avec le statut 'demande creee'.");
        } catch (SQLException e) {
            mv.setView("/visaFormError.jsp");
            mv.addData("success", false);
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("formData", formData);
        } catch (IllegalArgumentException e) {
            mv.setView("/visaFormError.jsp");
            mv.addData("success", false);
            mv.addData("error", e.getMessage());
            mv.addData("validationErrors", demandeService.isObligatoire(formData));
            mv.addData("formData", formData);
        }

        return mv;
    }

    // Mise a jour demande existante
    @MethodeAnnotation("/visa/form/update")
    @PostMapping
    public ModelView update(Map<String, Object> formData){
        ModelView mv = new ModelView("/resultDemande.jsp");

        try {
            boolean updated = demandeService.updateDemande(formData);
            mv.addData("success", updated);
            mv.addData("message", updated ? "Demande mise à jour avec succès." : "Aucune demande mise à jour.");
            mv.addData("action", "update");
        } catch (SQLException e) {
            mv.setView("/visaFormError.jsp");
            mv.addData("success", false);
            mv.addData("error", "Erreur base de donnees: " + e.getMessage());
            mv.addData("formData", formData);
        } catch (IllegalArgumentException e) {
            mv.setView("/visaFormError.jsp");
            mv.addData("success", false);
            mv.addData("error", e.getMessage());
            mv.addData("validationErrors", demandeService.isObligatoire(formData));
            mv.addData("formData", formData);
        }
        return mv;
    }
}
