package controllers;

import annotation.Api;
import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import annotation.RequestParam;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import modelview.ModelView;
import models.PieceFournie;
import services.DemandeVerrouilleeException;
import services.ScanService;
import util.DownloadFileResponse;
import util.FileUpload;

@ClasseAnnotation("/demande")
public class ScanController {

    private final ScanService scanService = new ScanService();

    @MethodeAnnotation("/{id}/scan")
    @GetMapping
    public ModelView scanPage(@RequestParam("id") long demandeId, Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/scanDemande.jsp");
        mv.addData("demandeId", demandeId); 

        try {
            Map<String, Object> demande = scanService.getDemandeScanInfo(demandeId);
            if (demande == null) {
                mv.addData("error", "Demande introuvable.");
                return mv;
            }

            List<Map<String, Object>> listePiecesAttendues = scanService.getListePiecesAttendues(demandeId);
            boolean demandeComplete = scanService.isDemandeComplete(demandeId);

            mv.addData("demande", demande);
            mv.addData("reference", demande.get("refDemande") != null ? String.valueOf(demande.get("refDemande")) : "");
            String nom = demande.get("nom") != null ? String.valueOf(demande.get("nom")) : "";
            String prenom = demande.get("prenom") != null ? String.valueOf(demande.get("prenom")) : "";
            mv.addData("nomComplet", (nom + " " + prenom).trim());
            mv.addData("listePiecesAttendues", listePiecesAttendues);
            mv.addData("demandeComplete", demandeComplete);

            String success = queryParams != null && queryParams.get("success") != null
                ? String.valueOf(queryParams.get("success"))
                : null;
            String message = queryParams != null && queryParams.get("message") != null
                ? String.valueOf(queryParams.get("message"))
                : null;
            String error = queryParams != null && queryParams.get("error") != null
                ? String.valueOf(queryParams.get("error"))
                : null;

            if ("1".equals(success) && message != null) {
                mv.addData("success", true);
                mv.addData("message", message);
            }
            if (error != null && !error.trim().isEmpty()) {
                mv.addData("error", error);
            }
        } catch (SQLException e) {
            mv.addData("error", "Erreur lors du chargement de l'ecran de scan: " + e.getMessage());
        }

        return mv;
    }

    @MethodeAnnotation("/{demandeId}/piece/{pieceRefId}/upload")
    @PostMapping
    @Api
    public Map<String, Object> uploadPiece(
        @RequestParam("demandeId") long demandeId,
        @RequestParam("pieceRefId") long pieceRefId,
        @RequestParam("fichier") FileUpload fichier
    ) throws SQLException {
        Map<String, Object> result = new HashMap<>();
        PieceFournie pieceFournie = scanService.uploadPiece(demandeId, pieceRefId, fichier);
        result.put("status", "success");
        result.put("message", "Fichier scanne enregistre avec succes.");
        result.put("demandeId", demandeId);
        result.put("pieceRefId", pieceRefId);
        result.put("fileName", pieceFournie != null ? pieceFournie.getNom_fichier() : "");
        result.put("next", "/demande/" + demandeId + "/piece/" + pieceRefId + "/download");
        return result;
    }

    @MethodeAnnotation("/{demandeId}/verrouiller")
    @PostMapping
    public ModelView verrouillerDemande(@RequestParam("demandeId") long demandeId) {
        try {
            scanService.verrouillerDemande(demandeId);
            String refDemande = scanService.findRefDemandeById(demandeId);
            if (refDemande == null || refDemande.trim().isEmpty()) {
                return new ModelView(buildScanRedirectSuccess(demandeId, "Demande verrouillee avec succes."));
            }
            String encoded = URLEncoder.encode(refDemande, StandardCharsets.UTF_8);
            return new ModelView("redirect:/suivi?ref=" + encoded + "&success=1");
        } catch (IllegalStateException | IllegalArgumentException | SQLException e) {
            return new ModelView(buildScanRedirectError(demandeId, e.getMessage()));
        }
    }

    @MethodeAnnotation("/{demandeId}/piece/{pieceRefId}/download")
    @GetMapping
    public DownloadFileResponse downloadPiece(
        @RequestParam("demandeId") long demandeId,
        @RequestParam("pieceRefId") long pieceRefId
    ) throws SQLException {
        return scanService.downloadPiece(demandeId, pieceRefId);
    }

    private String buildScanRedirectSuccess(long demandeId, String message) {
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8);
        return "redirect:/demande/" + demandeId + "/scan?success=1&message=" + encoded;
    }

    private String buildScanRedirectError(long demandeId, String error) {
        String safeError = error == null ? "Operation impossible." : error;
        String encoded = URLEncoder.encode(safeError, StandardCharsets.UTF_8);
        return "redirect:/demande/" + demandeId + "/scan?error=" + encoded;
    }
}
