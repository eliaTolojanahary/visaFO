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
import models.PieceFournie;
import modelview.ModelView;
import services.AttestationPdfService;
import services.DemandeVerrouilleeException;
import services.DossierService;
import services.ScanService;
import util.DownloadFileResponse;
import util.FileUpload;

@ClasseAnnotation("/demande")
public class ScanController {

    private final ScanService scanService = new ScanService();
    private final DossierService dossierService = new DossierService();
    private final AttestationPdfService attestationPdfService = new AttestationPdfService();

    
    @MethodeAnnotation("/{id}/scan")
    @GetMapping
    public ModelView scanPage(@RequestParam("id") long demandeId, Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/scanDemande.jsp");
        mv.addData("demandeId", demandeId);
        try {
            mv.addData("dossierId", dossierService.getDossieridByDemande(demandeId));
        } catch (SQLException e) {
            mv.addData("error", "Erreur lors du chargement du dossier: " + e.getMessage());
            return mv;
        }

        try {
            Map<String, Object> demande = scanService.getDemandeScanInfo(demandeId);
            if (demande == null) {
                mv.addData("error", "Demande introuvable.");
                return mv;
            }

            List<Map<String, Object>> listePiecesAttendues = scanService.getListePiecesAttendues(demandeId);
            boolean demandeComplete = scanService.isDemandeComplete(demandeId);
            Map<String, Object> scanStatus = scanService.getScanStatus(demandeId);

            mv.addData("demande", demande);
            mv.addData("reference", demande.get("refDemande") != null ? String.valueOf(demande.get("refDemande")) : "");
            String nom = demande.get("nom") != null ? String.valueOf(demande.get("nom")) : "";
            String prenom = demande.get("prenom") != null ? String.valueOf(demande.get("prenom")) : "";
            mv.addData("nomComplet", (nom + " " + prenom).trim());
            mv.addData("listePiecesAttendues", listePiecesAttendues);
            mv.addData("demandeComplete", demandeComplete);
            mv.addData("scanStatus", scanStatus);
            mv.addData("photoUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("photoUploaded")));
            mv.addData("signatureUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("signatureUploaded")));

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

    /**
     * POST /api/demandes/{demandeId}/dossiers/{dossierId}/signature
     *
     * Corps JSON attendu : { "dataUrl": "data:image/png;base64,..." }
     *
     * Réponses :
     *   200 – { success: true, id, nomFichier, uploadedAt, demandeComplete }
     *   400 – { success: false, error: "..." }   (base64 invalide, taille dépassée)
     *   404 – { success: false, error: "..." }   (demande/dossier absent)
     *   423 – { success: false, error: "..." }   (demande verrouillée)
     */
    @MethodeAnnotation("/{demandeId}/dossiers/{dossierId}/signature")
    @PostMapping
    @Api
    public Map<String, Object> uploadSignature(
        @RequestParam("demandeId") long demandeId,
        @RequestParam("dossierId") long dossierId,
        @RequestParam("dataUrl") String dataUrl
    ) throws SQLException {
        Map<String, Object> result = new HashMap<>();
        try {
            PieceFournie pieceFournie = scanService.sauvegarderSignatureCanvas(dataUrl, demandeId, dossierId);
            Map<String, Object> scanStatus = scanService.getScanStatus(demandeId);

            result.put("success", true);
            result.put("id", pieceFournie != null ? pieceFournie.getId() : null);
            result.put("nomFichier", pieceFournie != null ? pieceFournie.getNom_fichier() : "");
            result.put("uploadedAt", pieceFournie != null && pieceFournie.getUploaded_at() != null
                ? pieceFournie.getUploaded_at().toString() : "");
            result.put("demandeComplete", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("scanComplet")));
            result.put("photoUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("photoUploaded")));
            result.put("signatureUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("signatureUploaded")));
            result.put("locked", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("locked")));
            // pieceRefId réel pour que le JS puisse identifier la bonne card
            result.put("pieceRefId", pieceFournie != null && pieceFournie.getPiece_ref() != null
                ? pieceFournie.getPiece_ref().getId() : null);
        } catch (IllegalArgumentException e) {
            result.put("success", false);
            result.put("error", e.getMessage());
            result.put("httpStatus", 400);
        } catch (DemandeVerrouilleeException e) {
            result.put("success", false);
            result.put("error", e.getMessage());
            result.put("httpStatus", 423);
        } catch (SQLException e) {
            result.put("success", false);
                result.put("error", "Erreur interne: " + e.getMessage());
            result.put("httpStatus", 500);
        }
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
@MethodeAnnotation("/{demandeId}/dossiers/{dossierId}/photo-identite")
@PostMapping
@Api
public Map<String, Object> uploadPhotoIdentite(
    @RequestParam("demandeId") long demandeId,
    @RequestParam("dossierId") long dossierId,
    @RequestParam("file") FileUpload file
) throws SQLException {

    Map<String, Object> result = new HashMap<>();

    try {
        PieceFournie pieceFournie = scanService.sauvegarderPhotoIdentite(
            file,
            demandeId,
            dossierId
        );
        Map<String, Object> scanStatus = scanService.getScanStatus(demandeId);

        result.put("status", "success");
        result.put("success", true);
        result.put("message", "Photo d'identité uploadée avec succès.");
        result.put("id", pieceFournie.getId());
        result.put("nomFichier", pieceFournie.getNom_fichier());
        result.put(
            "uploadedAt",
            pieceFournie.getUploaded_at() != null
                ? pieceFournie.getUploaded_at().toString()
                : ""
        );
        result.put("demandeId", demandeId);
        result.put("dossierId", dossierId);
        result.put("photoUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("photoUploaded")));
        result.put("signatureUploaded", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("signatureUploaded")));
        result.put("demandeComplete", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("scanComplet")));
        result.put("locked", scanStatus != null && Boolean.TRUE.equals(scanStatus.get("locked")));

    } catch (DemandeVerrouilleeException e) {

        result.put("status", "error");
        result.put("success", false);
        result.put(
            "message",
            "Le dossier est verrouillé. Aucune modification n'est possible."
        );
        result.put("code", 403);

    } catch (IllegalArgumentException e) {

        result.put("status", "error");
        result.put("success", false);
        result.put("message", e.getMessage());
        result.put("code", 400);
    }

    return result;
}

    @MethodeAnnotation("/{id}/fiche")
    @GetMapping
    public ModelView ficheDemande(@RequestParam("id") long demandeId) {
        ModelView mv = new ModelView("/ficheDemande.jsp");

        try {
            Map<String, Object> fiche = scanService.getFicheDemandeData(demandeId);
            if (fiche == null) {
                mv.addData("error", "Demande introuvable.");
                return mv;
            }

            mv.addData("demandeId", demandeId);
            mv.addData("dossierId", dossierService.getDossieridByDemande(demandeId));
            mv.addData("demande", fiche);
            mv.addData("reference", fiche.get("ref_demande"));
            mv.addData("nomComplet", buildNomComplet(fiche));
            mv.addData("listePiecesAttendues", fiche.get("pieces"));
            mv.addData("demandeComplete", Boolean.TRUE.equals(fiche.get("scanComplet")));
            mv.addData("photoUploaded", Boolean.TRUE.equals(fiche.get("photoUploaded")));
            mv.addData("signatureUploaded", Boolean.TRUE.equals(fiche.get("signatureUploaded")));
            mv.addData("attestationDisponible", Boolean.TRUE.equals(fiche.get("locked")));
        } catch (SQLException e) {
            mv.addData("error", "Erreur lors du chargement de la fiche: " + e.getMessage());
        }

        return mv;
    }

    @MethodeAnnotation("/{id}/attestation")
    @GetMapping
    public DownloadFileResponse attestationPdf(@RequestParam("id") long demandeId) throws SQLException {
        return attestationPdfService.genererAttestation(demandeId);
    }

    @MethodeAnnotation("/{demandeId}/scan-status")
    @GetMapping
    @Api
    public Map<String, Object> scanStatus(@RequestParam("demandeId") long demandeId) throws SQLException {
        Map<String, Object> status = scanService.getScanStatus(demandeId);
        Map<String, Object> result = new HashMap<>();
        if (status == null) {
            result.put("success", false);
            result.put("error", "Demande introuvable.");
            return result;
        }

        result.putAll(status);
        result.put("success", true);
        return result;
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

    private String buildNomComplet(Map<String, Object> fiche) {
        String nom = fiche.get("nom") != null ? String.valueOf(fiche.get("nom")) : "";
        String prenom = fiche.get("prenom") != null ? String.valueOf(fiche.get("prenom")) : "";
        return (nom + " " + prenom).trim();
    }
}