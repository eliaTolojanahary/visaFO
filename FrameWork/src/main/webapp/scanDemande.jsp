<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    String ctx = request.getContextPath();

    /* ── Données injectées par le controller ── */
    Long    demandeId     = (Long)    request.getAttribute("demandeId");
    String  reference     = (String)  request.getAttribute("reference");
    String  nomComplet    = (String)  request.getAttribute("nomComplet");
    String  statutLibelle = (String)  request.getAttribute("statutLibelle");
    Boolean verrouille    = Boolean.TRUE.equals(request.getAttribute("verrouille"));

    /* ── Flash messages (pattern POST → redirect → GET) ── */
    String flashMessage = (String) request.getAttribute("flashMessage");
    String flashError   = (String) request.getAttribute("flashError");

    /* ── Pièces : List<Map> injectées par le controller ──
     *
     * Clés attendues par Map :
     *   "id"          Long   — piece_justificative_ref.id
     *   "libelle"     String — libellé affiché
     *   "scanStatut"  String — "SCANNÉ" | "EN_ATTENTE"
     *   "fileName"    String — nom_fichier dans piece_fournie (vide si absent)
     *   "fileSizeKo"  Long   — taille en Ko (0 si absent)
     *   "uploadedAt"  String — "dd/MM/yyyy HH:mm" (vide si absent)
     */
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> pieces = (List<Map<String, Object>>) request.getAttribute("pieces");

    /* ── Badge statut ── */
    String badgeClass = "badge-gray";
    String badgeLabel = statutLibelle != null ? statutLibelle : "Inconnu";
    if      ("SCAN TERMINÉ".equalsIgnoreCase(badgeLabel))            badgeClass = "badge-violet";
    else if ("EN ATTENTE DE SCAN".equalsIgnoreCase(badgeLabel))      badgeClass = "badge-orange";
    else if ("EN COURS".equalsIgnoreCase(badgeLabel))                badgeClass = "badge-blue";
    else if ("ERREUR SCAN".equalsIgnoreCase(badgeLabel))             badgeClass = "badge-red";

    /* ── Compteurs pour barre de progression (rendu serveur) ── */
    int totalPieces  = (pieces != null) ? pieces.size() : 0;
    int scannedCount = 0;
    if (pieces != null) {
        for (Map<String, Object> p : pieces) {
            if ("SCANNÉ".equalsIgnoreCase(String.valueOf(p.get("scanStatut")))) scannedCount++;
        }
    }
    int progressPct = (totalPieces > 0) ? (scannedCount * 100 / totalPieces) : 0;
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scan – <%= reference != null ? reference : "Demande" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
</head>
<body>
<div class="container">

    <%-- ══ BANDEAU VERROUILLÉ ═══════════════════════════════════ --%>
    <% if (verrouille) { %>
    <div class="lock-banner" role="alert">
        <span class="lock-icon">🔒</span>
        Dossier verrouillé – plus aucune modification possible
    </div>
    <% } %>

    <%-- ══ FLASH MESSAGES (inject après redirect POST → GET) ════ --%>
    <% if (flashMessage != null && !flashMessage.isEmpty()) { %>
    <div class="success-banner flash-banner" role="status">
        <strong>✓</strong> <%= flashMessage %>
    </div>
    <% } %>
    <% if (flashError != null && !flashError.isEmpty()) { %>
    <div class="error-banner flash-banner" role="alert">
        <strong>✗</strong> <%= flashError %>
    </div>
    <% } %>

    <%-- ══ EN-TÊTE ═══════════════════════════════════════════════ --%>
    <header class="scan-header">
        <div class="scan-header__meta">
            <div class="scan-header__ref">
                <span class="scan-header__ref-label">Référence</span>
                <span class="scan-header__ref-value"><%= reference != null ? reference : "-" %></span>
            </div>
            <span class="badge <%= badgeClass %>"><%= badgeLabel %></span>
        </div>
        <h1 class="scan-header__name"><%= nomComplet != null ? nomComplet : "-" %></h1>
        <p class="scan-header__hint">Gérez les documents scannés pour cette demande.</p>
    </header>

    <%-- ══ BARRE DE PROGRESSION GLOBALE ════════════════════════ --%>
    <div class="form-section progress-section">
        <div class="progress-header">
            <span class="progress-label">Progression du scan</span>
            <span class="progress-count" id="progressCount">
                <%= scannedCount %> / <%= totalPieces %> pièces
            </span>
        </div>
        <div class="progress-bar-track">
            <div class="progress-bar-fill"
                 id="progressBarFill"
                 style="width:<%= progressPct %>%"></div>
        </div>
    </div>

    <%-- ══ MESSAGE GLOBAL JS (uniquement pour Finaliser) ════════ --%>
    <div id="globalMessage" class="hidden" role="alert" aria-live="assertive"></div>

    <%-- ══ LISTE DES PIÈCES ══════════════════════════════════════ --%>
    <div class="form-section">
        <h2>Pièces justificatives</h2>

        <% if (pieces != null && !pieces.isEmpty()) { %>
        <div class="piece-list" id="pieceList">

        <%
            for (Map<String, Object> piece : pieces) {
                Long   pieceId      = piece.get("id")         != null ? Long.valueOf(String.valueOf(piece.get("id"))) : 0L;
                String pieceLibelle = piece.get("libelle")    != null ? String.valueOf(piece.get("libelle")) : "-";
                String scanStatut   = piece.get("scanStatut") != null ? String.valueOf(piece.get("scanStatut")) : "EN_ATTENTE";
                String fileName     = piece.get("fileName")   != null ? String.valueOf(piece.get("fileName"))  : "";
                String uploadedAt   = piece.get("uploadedAt") != null ? String.valueOf(piece.get("uploadedAt")): "";
                long   fileSizeKo   = 0L;
                try { fileSizeKo = Long.parseLong(String.valueOf(piece.get("fileSizeKo"))); } catch (Exception ignore) {}

                boolean scanned     = "SCANNÉ".equalsIgnoreCase(scanStatut);
                String  downloadUrl = ctx + "/demande/" + demandeId + "/piece/" + pieceId + "/download";
                String  uploadUrl   = ctx + "/demande/" + demandeId + "/piece/" + pieceId + "/upload";
        %>

            <div class="piece-card <%= scanned ? "piece-card--done" : "" %>"
                 id="piece-<%= pieceId %>">

                <%-- ── Libellé + point de statut ── --%>
                <div class="piece-card__info">
                    <span class="piece-card__status-dot <%= scanned ? "dot--green" : "dot--gray" %>"></span>
                    <span class="piece-card__label"><%= pieceLibelle %></span>
                </div>

                <%-- ── Bloc droite : métadonnées fichier + formulaire upload ── --%>
                <div class="piece-card__right">

                    <%-- État du fichier --%>
                    <% if (scanned && !fileName.isEmpty()) { %>
                    <div class="piece-card__file-meta">
                        <a href="<%= downloadUrl %>"
                           class="piece-card__download-link"
                           title="Télécharger <%= fileName %>">
                            📎 <%= fileName %>
                        </a>
                        <span class="piece-card__file-info">
                            <% if (fileSizeKo > 0) { %><%= fileSizeKo %>&thinsp;Ko<% } %>
                            <% if (!uploadedAt.isEmpty()) { %>&nbsp;·&nbsp;le&nbsp;<%= uploadedAt %><% } %>
                        </span>
                        <span class="badge badge-green badge-sm">Scanné</span>
                    </div>
                    <% } else { %>
                    <div class="piece-card__file-meta piece-card__file-meta--empty">
                        <span class="piece-card__no-file">Aucun fichier scanné</span>
                        <span class="badge badge-gray badge-sm">En attente</span>
                    </div>
                    <% } %>

                    <%-- ── Formulaire upload — masqué si dossier verrouillé ── --%>
                    <% if (!verrouille) { %>
                    <form class="piece-card__upload-form"
                          action="<%= uploadUrl %>"
                          method="post"
                          enctype="multipart/form-data"
                          novalidate>

                        <%-- Champs cachés pour identification serveur --%>
                        <input type="hidden" name="pieceRefId" value="<%= pieceId %>">
                        <input type="hidden" name="demandeId"  value="<%= demandeId %>">

                        <%-- Sélecteur fichier stylisé --%>
                        <label class="piece-card__file-label"
                               for="file-input-<%= pieceId %>">
                            <input type="file"
                                   id="file-input-<%= pieceId %>"
                                   name="fichier"
                                   class="visually-hidden js-upload-input"
                                   accept="image/jpeg,image/png,application/pdf"
                                   required
                                   data-piece-id="<%= pieceId %>">
                            <span class="piece-card__file-trigger btn-alt btn-sm">
                                Choisir un fichier
                            </span>
                            <span class="piece-card__file-chosen"
                                  id="chosen-<%= pieceId %>">
                                Aucun fichier choisi
                            </span>
                        </label>

                        <button type="submit"
                                class="btn-sm piece-card__upload-btn js-upload-btn"
                                id="upload-btn-<%= pieceId %>"
                                data-piece-id="<%= pieceId %>"
                                disabled>
                            <%= scanned ? "Remplacer" : "Uploader cette pièce" %>
                        </button>

                    </form>
                    <% } %>

                </div><%-- /piece-card__right --%>

            </div><%-- /piece-card --%>

        <% } /* fin for */ %>

        </div><%-- /piece-list --%>
        <% } else { %>
        <p class="hint-text">Aucune pièce justificative associée à cette demande.</p>
        <% } %>
    </div>

    <%-- ══ ACTIONS GLOBALES ══════════════════════════════════════ --%>
    <div class="form-actions scan-actions">
        <% if (!verrouille) { %>
        <button type="button"
                id="finalizeScanBtn"
                data-demande-id="<%= demandeId %>"
                class="btn-primary"
                <%= (scannedCount < totalPieces) ? "disabled" : "" %>>
            Finaliser le scan
        </button>
        <% } %>
        <a href="<%= ctx %>/demande/<%= demandeId != null ? demandeId : "" %>"
           class="btn-alt">
            Retour au dossier
        </a>
    </div>

</div><%-- /container --%>

<script src="<%= ctx %>/js/scanDemande.js"></script>
</body>
</html>
