package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import modelview.ModelView;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ScanDemandeController – Sprint 3 / feature/scan-front
 *
 * Mock complet : aucune dépendance service/DAO.
 * Trois états testables via ?etat= :
 *
 *   GET  /form/scan               → 2 pièces scannées / 5
 *   GET  /form/scan?etat=termine  → SCAN TERMINÉ + verrouillé
 *   GET  /form/scan?etat=vide     → 0 pièce scannée
 *
 *   POST /demande/{id}/piece/{pieceRefId}/upload    → mock upload individuel
 *   POST /demande/{id}/scan/finaliser               → mock finalisation
 */
@ClasseAnnotation("")
public class ScanDemandeController {

    // ══════════════════════════════════════════════════════════════════
    // GET /form/scan
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
            default:        injectEtatNormal(mv);
        }

        return mv;
    }

    // ══════════════════════════════════════════════════════════════════
    // POST /demande/{demandeId}/piece/{pieceRefId}/upload
    //
    // Pattern : reçoit le multipart, persiste dans piece_fournie,
    // redirige vers GET /form/scan?etat=normal avec flashMessage.
    //
    // En mock : redirige immédiatement avec un message de succès.
    // En production : remplacer la redirection par l'appel service réel.
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/*/piece/*/upload")
    @PostMapping
    public ModelView uploadPiece(Map<String, Object> formData) {
        /*
         * Variables attendues dans formData (envoyées par le <form>) :
         *   "demandeId"  — Long
         *   "pieceRefId" — Long
         *   "fichier"    — Part (multipart) → à traiter côté framework
         *
         * En production :
         *   1. Valider le fichier (type, taille)
         *   2. Écrire sur disque ou object storage
         *   3. INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier,
         *         nom_fichier, taille_bytes, mime_type)
         *      ON CONFLICT (demande_id, piece_ref_id) DO UPDATE SET ...
         *   4. Rediriger avec flashMessage
         */

        // ── Mock : on simule un succès systématique ──
        String demandeId = formData.get("demandeId") != null
            ? String.valueOf(formData.get("demandeId")) : "0";

        return new ModelView(
            "redirect:/demande/" + demandeId + "/scan?flash=upload_ok"
        );
    }

    // ══════════════════════════════════════════════════════════════════
    // POST /demande/{demandeId}/scan/finaliser
    //
    // En production :
    //   1. Vérifier que toutes les pièces cochées ont une entrée piece_fournie
    //   2. UPDATE demande
    //      SET statut_id = (SELECT id FROM statut_demande WHERE libelle = 'SCAN TERMINÉ'),
    //          verrouille = TRUE
    //      WHERE id = :demandeId
    //   3. Répondre JSON { success: true } (fetch côté JS puis reload)
    // ══════════════════════════════════════════════════════════════════

    @MethodeAnnotation("/demande/*/scan/finaliser")
    @PostMapping
    public ModelView finaliserScan(Map<String, Object> formData) {
        ModelView mv = new ModelView("json");
        mv.addData("success", true);
        mv.addData("message", "Scan finalisé – dossier verrouillé (mock).");
        return mv;
    }

    // ══════════════════════════════════════════════════════════════════
    // Helpers : injection données mock
    // ══════════════════════════════════════════════════════════════════

    private void injectEtatNormal(ModelView mv) {
        mv.addData("demandeId",     42L);
        mv.addData("reference",     "20250512-084521-DUP");
        mv.addData("nomComplet",    "RAKOTO Aina");
        mv.addData("statutLibelle", "EN COURS");
        mv.addData("verrouille",    false);
        mv.addData("flashMessage",  null);
        mv.addData("flashError",    null);
        mv.addData("pieces",        buildPiecesNormal());
    }

    private void injectEtatTermine(ModelView mv) {
        mv.addData("demandeId",     42L);
        mv.addData("reference",     "20250512-084521-DUP");
        mv.addData("nomComplet",    "RAKOTO Aina");
        mv.addData("statutLibelle", "SCAN TERMINÉ");
        mv.addData("verrouille",    true);
        mv.addData("flashMessage",  null);
        mv.addData("flashError",    null);
        mv.addData("pieces",        buildPiecesTermine());
    }

    private void injectEtatVide(ModelView mv) {
        mv.addData("demandeId",     99L);
        mv.addData("reference",     "20250513-101530-VISA");
        mv.addData("nomComplet",    "RANDRIA Jean-Pierre");
        mv.addData("statutLibelle", "EN ATTENTE DE SCAN");
        mv.addData("verrouille",    false);
        mv.addData("flashMessage",  null);
        mv.addData("flashError",    null);
        mv.addData("pieces",        buildPiecesVide());
    }

    // ──────────────────────────────────────────────────────────────────
    // Builders listes pièces mock
    //
    // Clés de chaque Map (= ce que le controller réel devra fournir) :
    //   "id"          Long   — piece_justificative_ref.id
    //   "libelle"     String — libellé de la pièce
    //   "scanStatut"  String — "SCANNÉ" | "EN_ATTENTE"
    //   "fileName"    String — piece_fournie.nom_fichier   (vide si absent)
    //   "fileSizeKo"  Long   — piece_fournie.taille_bytes / 1024 (0 si absent)
    //   "uploadedAt"  String — piece_fournie.uploaded_at formaté "dd/MM/yyyy HH:mm" (vide si absent)
    // ──────────────────────────────────────────────────────────────────

    private List<Map<String, Object>> buildPiecesNormal() {
        List<Map<String, Object>> list = new ArrayList<>();

        list.add(piece(1L, "02 photos d'identité",
                "SCANNÉ",    "photos_identite_rakoto.jpg", 84L,  "12/05/2025 08:47"));
        list.add(piece(2L, "Notice de renseignement",
                "SCANNÉ",    "notice_rakoto.pdf",          312L, "12/05/2025 08:52"));
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
                "SCANNÉ", "photos_identite_rakoto.jpg",       84L,  "12/05/2025 08:47"));
        list.add(piece(2L, "Notice de renseignement",
                "SCANNÉ", "notice_rakoto.pdf",                312L, "12/05/2025 08:52"));
        list.add(piece(3L, "Demande adressée au Ministère de l'Intérieur",
                "SCANNÉ", "demande_interieur_rakoto.pdf",     198L, "12/05/2025 09:01"));
        list.add(piece(4L, "Photocopie certifiée du visa en cours de validité",
                "SCANNÉ", "visa_rakoto.pdf",                  445L, "12/05/2025 09:08"));
        list.add(piece(5L, "Photocopie certifiée de la première page du passeport",
                "SCANNÉ", "passeport_p1_rakoto.pdf",          220L, "12/05/2025 09:15"));

        return list;
    }

    private List<Map<String, Object>> buildPiecesVide() {
        List<Map<String, Object>> list = new ArrayList<>();

        list.add(piece(1L,  "02 photos d'identité",                                 "EN_ATTENTE", "", 0L, ""));
        list.add(piece(2L,  "Notice de renseignement",                               "EN_ATTENTE", "", 0L, ""));
        list.add(piece(3L,  "Demande adressée au Ministère de l'Intérieur",          "EN_ATTENTE", "", 0L, ""));
        list.add(piece(4L,  "Photocopie certifiée du visa en cours de validité",     "EN_ATTENTE", "", 0L, ""));
        list.add(piece(5L,  "Photocopie certifiée de la première page du passeport", "EN_ATTENTE", "", 0L, ""));
        list.add(piece(8L,  "Extrait de casier judiciaire de moins de 3 mois",       "EN_ATTENTE", "", 0L, ""));
        list.add(piece(9L,  "Statut de la société",                                  "EN_ATTENTE", "", 0L, ""));

        return list;
    }

    private Map<String, Object> piece(Long id, String libelle,
                                      String scanStatut, String fileName,
                                      Long fileSizeKo, String uploadedAt) {
        Map<String, Object> m = new HashMap<>();
        m.put("id",          id);
        m.put("libelle",     libelle);
        m.put("scanStatut",  scanStatut);
        m.put("fileName",    fileName);
        m.put("fileSizeKo",  fileSizeKo);
        m.put("uploadedAt",  uploadedAt);
        return m;
    }
}