package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import annotation.Api;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import modelview.ModelView;

/**
 * ScanDemandeController – Sprint 3 / feature/scan-front
 *
 * États testables via ?etat= :
 *
 *   GET  /form/scan               → 2/5 scannées, demandeComplete = false
 *   GET  /form/scan?etat=termine  → SCAN TERMINÉ + verrouillé
 *   GET  /form/scan?etat=vide     → 0/7 scannées, demandeComplete = false
 *   GET  /form/scan?etat=complet  → 5/5 scannées, demandeComplete = true → bouton actif
 *
 *   POST /demande/{id}/piece/{pieceRefId}/upload  → mock upload pièce
 *   POST /demande/{id}/verrouiller                → mock verrouillage
 */
@ClasseAnnotation("")
public class ScanDemandeController {

    // ══════════════════════════════════════════════════════════════════
    // GET /demande/{id}/scan
    // Route réelle (Sprint 3) — chargement des données depuis la BD
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/{id}/scan")
    @GetMapping
    public ModelView getScanPage(Map<String, Object> pathParams, 
                                 Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/scanDemande.jsp");

        Long demandeId = pathParams != null && pathParams.get("id") != null
            ? Long.parseLong(String.valueOf(pathParams.get("id")))
            : 0L;

        if (demandeId <= 0) {
            mv.setView("redirect:/");
            return mv;
        }

        /*
         * TODO (Sprint 3 Back-End) : En production
         *
         * 1. Charger la demande via DemandeService.findDemande(demandeId)
         * 2. Charger la liste des pièces attendues (demande_piece cochée = TRUE)
         * 3. Charger les pièces fournies (piece_fournie) pour cette demande
         * 4. Calculer isDemandeComplete() via ScanService
         * 5. Injecter dans mv :
         *    - demandeId, reference, nomComplet, statutLibelle, verrouille
         *    - pieces (List<Map>) avec les champs requis
         *    - flashMessage/flashError si présents en param query
         */

        String flash = queryParams != null && queryParams.get("flash") != null
            ? String.valueOf(queryParams.get("flash")) : "";
        String flashMessage = null;
        String flashError = null;
        if ("upload_ok".equalsIgnoreCase(flash)) {
            flashMessage = "Upload dummy OK";
        } else if ("verrouille_ok".equalsIgnoreCase(flash)) {
            flashMessage = "Verrouillage dummy OK";
        } else if ("upload_error".equalsIgnoreCase(flash)) {
            flashError = "Upload dummy en erreur";
        }

        // Mock : pour test du front-end — utiliser les données mock de test
        List<Map<String, Object>> pieces = buildPiecesNormal();
        mv.addData("demandeId",       demandeId);
        mv.addData("reference",       "REF-" + demandeId);
        mv.addData("nomComplet",      "Demandeur Test");
        mv.addData("statutLibelle",   "EN COURS");
        mv.addData("verrouille",      false);
        mv.addData("pieces",          pieces);
        mv.addData("flashMessage",    flashMessage);
        mv.addData("flashError",      flashError);

        return mv;
    }

    // ══════════════════════════════════════════════════════════════════
    // GET /form/scan
    // Route de test uniquement — avec mock data prédéfinies
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/form/scan")
    @GetMapping
    public ModelView getScanForm(Map<String, Object> queryParams) {
        ModelView mv = new ModelView("/scanDemande.jsp");

        String etat = queryParams != null && queryParams.get("etat") != null
            ? String.valueOf(queryParams.get("etat"))
            : "normal";

        switch (etat) {
            case "termine": injectEtatTermine(mv); break;
            case "vide":    injectEtatVide(mv);    break;
            case "complet": injectEtatComplet(mv); break;
            default:        injectEtatNormal(mv);
        }

        return mv;
    }

    // ══════════════════════════════════════════════════════════════════
    // POST /demande/{demandeId}/piece/{pieceRefId}/upload
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/{demandeId}/piece/{pieceRefId}/upload")
    @PostMapping
    @Api
    public Map<String, Object> uploadPiece(Map<String, Object> formData) {
        /*
         * En production :
         *   1. Récupérer le Part multipart "fichier"
         *   2. Valider (type MIME, taille)
         *   3. Persister sur disque / object storage
         *   4. INSERT INTO piece_fournie ... ON CONFLICT DO UPDATE
         *   5. Recalculer demandeComplete et rediriger avec flash
         */
        String demandeId = formData.get("demandeId") != null
            ? String.valueOf(formData.get("demandeId")) : "0";
        String pieceRefId = formData.get("pieceRefId") != null
            ? String.valueOf(formData.get("pieceRefId")) : "0";
        System.out.println("[STUB][UPLOAD] demandeId=" + demandeId + ", pieceRefId=" + pieceRefId);

        Map<String, Object> result = new HashMap<>();
        result.put("status", "success");
        result.put("message", "Upload dummy avec succes");
        result.put("demandeId", demandeId);
        result.put("pieceRefId", pieceRefId);
        result.put("next", "/demande/" + demandeId + "/piece/" + pieceRefId + "/download");
        return result;
    }

    // ══════════════════════════════════════════════════════════════════
    // POST /demande/{demandeId}/verrouiller
    //
    // En production :
    //   1. Vérifier demandeComplete (sécurité serveur, pas que côté client)
    //   2. UPDATE demande
    //      SET statut_id = (SELECT id FROM statut_demande WHERE libelle = 'SCAN TERMINÉ'),
    //          verrouille = TRUE
    //      WHERE id = :demandeId AND verrouille = FALSE
    //   3. Rediriger avec flashMessage succès
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/{demandeId}/verrouiller")
    @PostMapping
    @Api
    public Map<String, Object> verrouiller(Map<String, Object> formData) {
        String demandeId = formData.get("demandeId") != null
            ? String.valueOf(formData.get("demandeId")) : "0";
        System.out.println("[STUB][VERROUILLER] demandeId=" + demandeId);

        Map<String, Object> result = new HashMap<>();
        result.put("status", "success");
        result.put("message", "Dossier verrouille (dummy)");
        result.put("demandeId", demandeId);
        result.put("redirect", "/suivi?ref=REF-" + demandeId);
        return result;
    }

    // ══════════════════════════════════════════════════════════════════
    // GET /demande/{demandeId}/piece/{pieceRefId}/download
    //
    // Télécharge le fichier scanné pour une pièce justificative.
    //
    // En production :
    //   1. Charger piece_fournie via PieceFournieRepository
    //   2. Lire le fichier depuis le disque / object storage
    //   3. Envoyer le fichier au client avec bon Content-Type et Content-Disposition
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/{demandeId}/piece/{pieceRefId}/download")
    @GetMapping
    public ModelView downloadPiece(Long demandeId, Long pieceRefId) {
        /*
         * En production :
         * - Long demandeId    = (Long) pathParams.get("demandeId");
         * - Long pieceRefId   = (Long) pathParams.get("pieceRefId");
         * - PieceFournie pf   = pieceFournieRepo.recuperer(demandeId, pieceRefId);
         * - si pf != null : envoyer le fichier
         * - sinon : 404
         *
         * Important : utiliser un mécanisme de streaming pour les gros fichiers.
         * Exemple avec Servlet/JSP :
         *   response.setHeader("Content-Type", pf.mime_type);
         *   response.setHeader("Content-Disposition", 
         *     "attachment; filename=\"" + URLEncoder.encode(pf.nom_fichier, "UTF-8") + "\"");
         *   Files.copy(Paths.get(pf.chemin_fichier), response.getOutputStream());
         */

        String demandeIdStr = demandeId != null ? String.valueOf(demandeId) : "1";
        String pieceRefIdStr = pieceRefId != null ? String.valueOf(pieceRefId) : "0";
        System.out.println("[STUB][DOWNLOAD] demandeId=" + demandeIdStr + ", pieceRefId=" + pieceRefIdStr);

        // Mock pour l'instant
        return new ModelView("redirect:/demande/" + demandeIdStr + "/scan?flash=download_mock");
    }

    // ══════════════════════════════════════════════════════════════════
    // Helpers injection mock
    // ══════════════════════════════════════════════════════════════════

    /** 2/5 scannées — bouton verrouiller désactivé */
    private void injectEtatNormal(ModelView mv) {
        List<Map<String, Object>> pieces = buildPiecesNormal();
        mv.addData("demandeId",       42L);
        mv.addData("reference",       "20250512-084521-DUP");
        mv.addData("nomComplet",      "RAKOTO Aina");
        mv.addData("statutLibelle",   "EN COURS");
        mv.addData("verrouille",      false);
        mv.addData("demandeComplete", isComplete(pieces));   // false
        mv.addData("flashMessage",    null);
        mv.addData("flashError",      null);
        mv.addData("pieces",          pieces);
    }

    /** 5/5 scannées — bouton verrouiller actif */
    private void injectEtatComplet(ModelView mv) {
        List<Map<String, Object>> pieces = buildPiecesTermine();
        mv.addData("demandeId",       42L);
        mv.addData("reference",       "20250512-084521-DUP");
        mv.addData("nomComplet",      "RAKOTO Aina");
        mv.addData("statutLibelle",   "EN COURS");
        mv.addData("verrouille",      false);
        mv.addData("demandeComplete", isComplete(pieces));   // true
        mv.addData("flashMessage",    null);
        mv.addData("flashError",      null);
        mv.addData("pieces",          pieces);
    }

    /** Dossier verrouillé — plus d'actions possibles */
    private void injectEtatTermine(ModelView mv) {
        List<Map<String, Object>> pieces = buildPiecesTermine();
        mv.addData("demandeId",       42L);
        mv.addData("reference",       "20250512-084521-DUP");
        mv.addData("nomComplet",      "RAKOTO Aina");
        mv.addData("statutLibelle",   "SCAN TERMINÉ");
        mv.addData("verrouille",      true);
        mv.addData("demandeComplete", true);
        mv.addData("flashMessage",    null);
        mv.addData("flashError",      null);
        mv.addData("pieces",          pieces);
    }

    /** 0/7 scannées */
    private void injectEtatVide(ModelView mv) {
        List<Map<String, Object>> pieces = buildPiecesVide();
        mv.addData("demandeId",       99L);
        mv.addData("reference",       "20250513-101530-VISA");
        mv.addData("nomComplet",      "RANDRIA Jean-Pierre");
        mv.addData("statutLibelle",   "EN ATTENTE DE SCAN");
        mv.addData("verrouille",      false);
        mv.addData("demandeComplete", isComplete(pieces));   // false
        mv.addData("flashMessage",    null);
        mv.addData("flashError",      null);
        mv.addData("pieces",          pieces);
    }

    /**
     * Calcule demandeComplete côté serveur.
     * Règle : toutes les pièces doivent avoir scanStatut = "SCANNÉ".
     *
     * En production, cette logique sera dans le service :
     *   SELECT COUNT(*) = 0 FROM demande_piece dp
     *   LEFT JOIN piece_fournie pf ON pf.demande_id = dp.demande_id
     *                              AND pf.piece_ref_id = dp.piece_id
     *   WHERE dp.demande_id = :id AND dp.cochee = TRUE AND pf.id IS NULL
     */
    private boolean isComplete(List<Map<String, Object>> pieces) {
        if (pieces == null || pieces.isEmpty()) return false;
        for (Map<String, Object> p : pieces) {
            if (!"SCANNÉ".equalsIgnoreCase(String.valueOf(p.get("scanStatut")))) {
                return false;
            }
        }
        return true;
    }

    // ──────────────────────────────────────────────────────────────────
    // Builders listes pièces mock
    //
    // Clés de chaque Map :
    //   "id"          Long   — piece_justificative_ref.id
    //   "libelle"     String
    //   "scanStatut"  String — "SCANNÉ" | "EN_ATTENTE"
    //   "fileName"    String — vide si non scanné
    //   "fileSizeKo"  Long   — 0 si non scanné
    //   "uploadedAt"  String — vide si non scanné ("dd/MM/yyyy HH:mm")
    // ──────────────────────────────────────────────────────────────────

    private List<Map<String, Object>> buildPiecesNormal() {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(piece(1L, "02 photos d'identité",
                "SCANNÉ",     "photos_identite_rakoto.jpg", 84L,  "12/05/2025 08:47"));
        list.add(piece(2L, "Notice de renseignement",
                "SCANNÉ",     "notice_rakoto.pdf",          312L, "12/05/2025 08:52"));
        list.add(piece(3L, "Demande adressée au Ministère de l'Intérieur",
                "EN_ATTENTE", "", 0L, ""));
        list.add(piece(4L, "Photocopie certifiée du visa en cours de validité",
                "EN_ATTENTE", "", 0L, ""));
        list.add(piece(5L, "Photocopie certifiée de la première page du passeport",
                "EN_ATTENTE", "", 0L, ""));
        return list;
    }

    private List<Map<String, Object>> buildPiecesTermine() {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(piece(1L, "02 photos d'identité",
                "SCANNÉ", "photos_identite_rakoto.jpg",   84L,  "12/05/2025 08:47"));
        list.add(piece(2L, "Notice de renseignement",
                "SCANNÉ", "notice_rakoto.pdf",            312L, "12/05/2025 08:52"));
        list.add(piece(3L, "Demande adressée au Ministère de l'Intérieur",
                "SCANNÉ", "demande_interieur_rakoto.pdf", 198L, "12/05/2025 09:01"));
        list.add(piece(4L, "Photocopie certifiée du visa en cours de validité",
                "SCANNÉ", "visa_rakoto.pdf",              445L, "12/05/2025 09:08"));
        list.add(piece(5L, "Photocopie certifiée de la première page du passeport",
                "SCANNÉ", "passeport_p1_rakoto.pdf",      220L, "12/05/2025 09:15"));
        return list;
    }

    private List<Map<String, Object>> buildPiecesVide() {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(piece(1L, "02 photos d'identité",                                 "EN_ATTENTE", "", 0L, ""));
        list.add(piece(2L, "Notice de renseignement",                               "EN_ATTENTE", "", 0L, ""));
        list.add(piece(3L, "Demande adressée au Ministère de l'Intérieur",          "EN_ATTENTE", "", 0L, ""));
        list.add(piece(4L, "Photocopie certifiée du visa en cours de validité",     "EN_ATTENTE", "", 0L, ""));
        list.add(piece(5L, "Photocopie certifiée de la première page du passeport", "EN_ATTENTE", "", 0L, ""));
        list.add(piece(8L, "Extrait de casier judiciaire de moins de 3 mois",       "EN_ATTENTE", "", 0L, ""));
        list.add(piece(9L, "Statut de la société",                                  "EN_ATTENTE", "", 0L, ""));
        return list;
    }

    private Map<String, Object> piece(Long id, String libelle,
                                      String scanStatut, String fileName,
                                      Long fileSizeKo, String uploadedAt) {
        Map<String, Object> m = new HashMap<>();
        m.put("id",         id);
        m.put("libelle",    libelle);
        m.put("scanStatut", scanStatut);
        m.put("fileName",   fileName);
        m.put("fileSizeKo", fileSizeKo);
        m.put("uploadedAt", uploadedAt);
        return m;
    }
}