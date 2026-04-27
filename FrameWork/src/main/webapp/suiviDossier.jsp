<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    String ctx = request.getContextPath();

    /* ── Données injectées par SuiviController ── */
    Long   demandeId     = (Long)   request.getAttribute("demandeId");
    String reference     = (String) request.getAttribute("reference");
    String nomComplet    = (String) request.getAttribute("nomComplet");
    String statutLibelle = (String) request.getAttribute("statutLibelle");

    /* ── Flash messages ── */
    String flashMessage = (String) request.getAttribute("flashMessage");
    String flashError   = (String) request.getAttribute("flashError");

    /*
     * ── Pièces fournies : List<Map> injectée par SuiviController ──
     *
     * Clés attendues par Map :
     *   "pieceLibelle"  String — libellé de la pièce justificative
     *   "fileName"      String — nom du fichier (vide si absent)
     *   "pieceRefId"    Long   — id de la piece_justificative_ref
     */
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> piecesScannees =
        (List<Map<String, Object>>) request.getAttribute("piecesScannees");

    /* ── Badge statut ── */
    String badgeClass = "badge-gray";
    String badgeLabel = statutLibelle != null ? statutLibelle : "Inconnu";
    if      ("SCAN TERMINÉ".equalsIgnoreCase(badgeLabel))           badgeClass = "badge-violet";
    else if ("EN COURS DE TRAITEMENT".equalsIgnoreCase(badgeLabel)) badgeClass = "badge-blue";
    else if ("CRÉÉ".equalsIgnoreCase(badgeLabel))                   badgeClass = "badge-orange";
    else if ("REJETÉ".equalsIgnoreCase(badgeLabel))                 badgeClass = "badge-red";
    else if ("APPROUVÉ".equalsIgnoreCase(badgeLabel))               badgeClass = "badge-green";

    boolean scanTermine = "SCAN TERMINÉ".equalsIgnoreCase(badgeLabel);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Suivi – <%= reference != null ? reference : "Demande" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
</head>
<body>
<div class="container">

    <%-- ══ FLASH MESSAGES ══════════════════════════════════════════ --%>
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

    <%-- ══ EN-TÊTE ════════════════════════════════════════════════ --%>
    <header class="scan-header">
        <div class="scan-header__meta">
            <div class="scan-header__ref">
                <span class="scan-header__ref-label">Référence</span>
                <span class="scan-header__ref-value"><%= reference != null ? reference : "-" %></span>
            </div>
            <span class="badge <%= badgeClass %>"><%= badgeLabel %></span>
        </div>
        <h1 class="scan-header__name"><%= nomComplet != null ? nomComplet : "-" %></h1>
        <p class="scan-header__hint">Suivi du dossier et documents scannés.</p>
    </header>

    <%-- ══ SECTION DOCUMENTS SCANNÉS ════════════════════════════ --%>
    <div class="form-section">
        <h2>Documents scannés</h2>

        <% if (piecesScannees != null && !piecesScannees.isEmpty()) { %>
        <div class="piece-list">

        <%
            for (Map<String, Object> piece : piecesScannees) {
                String pieceLibelle = piece.get("pieceLibelle") != null
                    ? String.valueOf(piece.get("pieceLibelle")) : "-";
                String fileName = piece.get("fileName") != null
                    ? String.valueOf(piece.get("fileName")) : "";
                Long   pieceRefId = piece.get("pieceRefId") != null
                    ? Long.valueOf(String.valueOf(piece.get("pieceRefId"))) : 0L;

                boolean hasFile   = !fileName.isEmpty();
                String  downloadUrl = ctx + "/demande/" + demandeId + "/piece/" + pieceRefId + "/download";
        %>
            <div class="piece-card <%= hasFile ? "piece-card--done" : "" %>">
                <div class="piece-card__info">
                    <span class="piece-card__status-dot <%= hasFile ? "dot--green" : "dot--gray" %>"></span>
                    <span class="piece-card__label"><%= pieceLibelle %></span>
                </div>

                <div class="piece-card__right">
                    <% if (hasFile) { %>
                    <div class="piece-card__file-meta">
                        <a href="<%= downloadUrl %>"
                           class="piece-card__download-link"
                           title="Télécharger <%= fileName %>">
                            📎 <%= fileName %>
                        </a>
                        <span class="badge badge-green badge-sm">Scanné</span>
                    </div>
                    <% } else { %>
                    <div class="piece-card__file-meta piece-card__file-meta--empty">
                        <span class="piece-card__no-file">Aucun fichier scanné</span>
                        <span class="badge badge-gray badge-sm">En attente</span>
                    </div>
                    <% } %>
                </div><%-- /piece-card__right --%>

            </div><%-- /piece-card --%>
        <% } /* fin for */ %>

        </div><%-- /piece-list --%>
        <% } else { %>
        <p class="hint-text">Aucun document scanné pour l'instant.</p>
        <% } %>
    </div>

    <%-- ══ ACTIONS ════════════════════════════════════════════════ --%>
    <div class="form-actions scan-actions">
        <% if (!scanTermine) { %>
        <a href="<%= ctx %>/demande/<%= demandeId != null ? demandeId : "" %>/scan"
           class="btn-primary">
            Aller au scan
        </a>
        <% } %>
        <a href="<%= ctx %>/demande/<%= demandeId != null ? demandeId : "" %>"
           class="btn-alt">
            Retour au dossier
        </a>
    </div>

</div><%-- /container --%>
</body>
</html>
