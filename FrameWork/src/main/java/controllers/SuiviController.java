package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Map;
import modelview.ModelView;
import repo.DemandeRepository;
import services.DemandeService;

@ClasseAnnotation("")
public class SuiviController {
    // Dans controllers/SuiviController.java

    @MethodeAnnotation("/suivi")
    @PostMapping
    public ModelView postSuivi(Map<String, Object> formData) {
        String idParam = null;
        if (formData != null && formData.get("demande_id") != null) {
            idParam = String.valueOf(formData.get("demande_id"));
        } else if (formData != null && formData.get("ref") != null) {
            idParam = String.valueOf(formData.get("ref"));
        }
    
        if (idParam == null || idParam.isEmpty()) {
            return new ModelView("redirect:/dashboard");
        }
    
        // Tenter de parser en Long : si succès, c'est un id, sinon c'est une ref
        try {
            Long.parseLong(idParam);
            return new ModelView("redirect:/suivi?id=" + idParam);
        } catch (NumberFormatException e) {
            // Ce n'est pas un nombre, c'est une référence
            try {
                String encoded = URLEncoder.encode(idParam, StandardCharsets.UTF_8.name());
                return new ModelView("redirect:/suivi?ref=" + encoded);
            } catch (UnsupportedEncodingException ex) {
                return new ModelView("redirect:/dashboard");
            }
        }
    }

    @MethodeAnnotation("/suivi")
    @GetMapping
    public ModelView getSuivi(Map<String, Object> queryParams) {
        String idParam = queryParams != null && queryParams.get("id") != null
                ? String.valueOf(queryParams.get("id")) : null;
        String refParam = queryParams != null && queryParams.get("ref") != null
                ? String.valueOf(queryParams.get("ref")) : null;

        ModelView mv = new ModelView("/suiviDossier.jsp");
        try {
            DemandeService demandeService = new DemandeService(); // ou injection
            Map<String, Object> demande = null;

            if (idParam != null && !idParam.isEmpty()) {
                try {
                    long demandeId = Long.parseLong(idParam);
                    demande = demandeService.getDemandeMapById(demandeId);
                } catch (NumberFormatException e) {
                    // id invalide
                }
            } else if (refParam != null && !refParam.isEmpty()) {
                // Utiliser la méthode existante getDemandeByRef (à ajouter dans service)
                demande = demandeService.getDemandeByRef(refParam);
            }

            if (demande == null) {
                return new ModelView("redirect:/dashboard");
            }

            mv.addData("demande", demande);
            // piecesScannees et listePiecesAttendues seront fournies plus tard par le service scan
            mv.addData("piecesScannees", new ArrayList<>());
            mv.addData("listePiecesAttendues", new ArrayList<>());
            mv.addData("statutLibelle", demande.get("statutLibelle"));
            mv.addData("isLocked", demande.get("verrouille") != null ? demande.get("verrouille") : false);

        } catch (SQLException e) {
            mv.addData("error", "Erreur chargement dossier: " + e.getMessage());
        }
        return mv;
}
}
