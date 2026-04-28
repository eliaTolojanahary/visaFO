package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import annotation.RequestParam;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

import modelview.ModelView;
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

        try {
            Map<String, Object> demande = scanService.getDemandeScanInfo(demandeId);
            if (demande == null) {
                mv.addData("error", "Demande introuvable.");
                return mv;
            }

            List<Map<String, Object>> listePiecesAttendues = scanService.getListePiecesAttendues(demandeId);
            boolean demandeComplete = scanService.isDemandeComplete(demandeId);

            mv.addData("demande", demande);
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
    public ModelView uploadPiece(
        @RequestParam("demandeId") long demandeId,
        @RequestParam("pieceRefId") long pieceRefId,
        @RequestParam("fichier") FileUpload fichier
    ) {
        try {
            scanService.uploadPiece(demandeId, pieceRefId, fichier);
            return new ModelView(buildScanRedirectSuccess(demandeId, "Fichier scanne enregistre avec succes."));
        } catch (DemandeVerrouilleeException | IllegalArgumentException | SQLException e) {
            return new ModelView(buildScanRedirectError(demandeId, e.getMessage()));
        }
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
