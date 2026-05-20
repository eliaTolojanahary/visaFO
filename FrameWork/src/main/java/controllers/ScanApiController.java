package controllers;

import annotation.Api;
import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import annotation.RequestParam;
import dao.DossierDemandeDao;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import models.DossierDemande;
import models.PieceFournie;
import repo.DossierDemandeRepository;
import services.ScanIncompleteException;
import services.ScanService;

@ClasseAnnotation("")
public class ScanApiController {

    private final ScanService scanService = new ScanService();
    private final DossierDemandeDao dossierDemandeDao = new DossierDemandeRepository();

    @MethodeAnnotation("/api/demandes/{demandeId}/scan-status")
    @GetMapping
    @Api
    public Map<String, Object> scanStatus(@RequestParam("demandeId") long demandeId) {
        Map<String, Object> response = new HashMap<>();

        try {
            Map<String, Object> demandeInfo = scanService.getDemandeScanInfo(demandeId);
            if (demandeInfo == null) {
                response.put("success", false);
                response.put("httpStatus", 404);
                response.put("error", "Demande introuvable.");
                return response;
            }

            List<Map<String, Object>> pieces = buildPiecesResponse(scanService.getListePiecesAttendues(demandeId));
            response.put("success", true);
            response.put("scanComplet", scanService.verifierScanComplet(demandeId));
            response.put("pieces", pieces);
            response.put("photoId", findPieceIdByLabel(pieces, "Photo d'identite (webcam)"));
            response.put("signatureId", findPieceIdByLabel(pieces, "Signature numerique"));
            response.put("httpStatus", 200);
            return response;
        } catch (SQLException e) {
            response.put("success", false);
            response.put("httpStatus", 500);
            response.put("error", "Erreur lors du chargement du statut scan: " + e.getMessage());
            return response;
        }
    }

    @MethodeAnnotation("/api/dossiers/{dossierId}/demandes/{demandeId}/finaliser-scan")
    @PostMapping
    @Api
    public Map<String, Object> finaliserScan(
        @RequestParam("dossierId") long dossierId,
        @RequestParam("demandeId") long demandeId
    ) {
        Map<String, Object> response = new HashMap<>();

        try {
            DossierDemande dossierDemande = dossierDemandeDao.findDossierDemande(dossierId, demandeId);
            if (dossierDemande == null) {
                response.put("success", false);
                response.put("httpStatus", 404);
                response.put("error", "Dossier ou demande introuvable.");
                return response;
            }

            boolean success = scanService.marquerScanTermine(dossierId, demandeId);
            if (!success) {
                response.put("success", false);
                response.put("httpStatus", 500);
                response.put("error", "Erreur lors de la finalisation du scan.");
                return response;
            }

            DossierDemande updated = dossierDemandeDao.findDossierDemande(dossierId, demandeId);
            response.put("success", true);
            response.put("httpStatus", 200);
            response.put("message", "Scan finalisé");
            response.put("dossier", buildDossierResponse(updated));
            return response;
        } catch (ScanIncompleteException e) {
            response.put("success", false);
            response.put("httpStatus", 400);
            response.put("error", e.getMessage());
            return response;
        } catch (IllegalArgumentException e) {
            response.put("success", false);
            response.put("httpStatus", 404);
            response.put("error", e.getMessage());
            return response;
        } catch (SQLException e) {
            response.put("success", false);
            response.put("httpStatus", 500);
            response.put("error", "Erreur métier lors de la finalisation du scan: " + e.getMessage());
            return response;
        }
    }

    private List<Map<String, Object>> buildPiecesResponse(List<Map<String, Object>> piecesAttendues) {
        List<Map<String, Object>> pieces = new ArrayList<>();
        if (piecesAttendues == null) {
            return pieces;
        }

        for (Map<String, Object> row : piecesAttendues) {
            Map<String, Object> piece = new HashMap<>();
            Object pieceFournieObj = row.get("pieceFournie");
            boolean scanned = pieceFournieObj instanceof PieceFournie;
            piece.put("id", scanned ? ((PieceFournie) pieceFournieObj).getId() : row.get("pieceRefId"));
            piece.put("nom", row.get("pieceLibelle"));
            piece.put("statut", row.get("scanStatut"));
            piece.put("cochee", scanned);
            pieces.add(piece);
        }

        return pieces;
    }

    private Long findPieceIdByLabel(List<Map<String, Object>> pieces, String label) {
        if (pieces == null || label == null) {
            return null;
        }

        for (Map<String, Object> piece : pieces) {
            Object nom = piece.get("nom");
            if (label.equalsIgnoreCase(String.valueOf(nom))) {
                Object id = piece.get("id");
                try {
                    return id == null ? null : Long.valueOf(id.toString());
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }

    private Map<String, Object> buildDossierResponse(DossierDemande dossierDemande) {
        Map<String, Object> dossier = new HashMap<>();
        if (dossierDemande == null) {
            return dossier;
        }

        dossier.put("id", dossierDemande.getDossierId());
        dossier.put("demandeId", dossierDemande.getDemandeId());
        dossier.put("scanTermine", dossierDemande.isScanTermine());
        dossier.put("dateScanComplete", dossierDemande.getDateScanComplete());
        return dossier;
    }
}