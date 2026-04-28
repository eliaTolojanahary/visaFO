package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import java.sql.SQLException;
import java.util.Map;
import modelview.ModelView;
import services.ScanService;

@ClasseAnnotation("")
public class SuiviController {

    private final ScanService scanService = new ScanService();

    @MethodeAnnotation("/suivi")
    @GetMapping
    public ModelView suivi(Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/suiviDossier.jsp");

        String ref = queryParams != null && queryParams.get("ref") != null
            ? String.valueOf(queryParams.get("ref"))
            : null;

        if (ref == null || ref.trim().isEmpty()) {
            mv.addData("error", "Le parametre ref est obligatoire.");
            return mv;
        }

        try {
            Map<String, Object> suivi = scanService.getSuiviByRefDemande(ref);
            if (suivi == null) {
                mv.addData("error", "Aucun dossier trouve pour la reference: " + ref);
                return mv;
            }

            String success = queryParams != null && queryParams.get("success") != null
                ? String.valueOf(queryParams.get("success"))
                : null;

            if ("1".equals(success)) {
                mv.addData("success", true);
                mv.addData("message", "Demande verrouillee. Le scan est termine.");
            }

            mv.addData("suivi", suivi);
            mv.addData("piecesScannees", suivi.get("piecesScannees"));
        } catch (SQLException e) {
            mv.addData("error", "Erreur lors du chargement du suivi: " + e.getMessage());
        }

        return mv;
    }
}
