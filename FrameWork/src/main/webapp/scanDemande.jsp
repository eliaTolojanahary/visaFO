<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    String ctx = request.getContextPath();

    /* ── Données injectées par le controller ── */
    Long   demandeId      = (Long)    request.getAttribute("demandeId");
    String reference      = (String)  request.getAttribute("reference");      // ex. "20240512-084521-DUP"
    String nomComplet     = (String)  request.getAttribute("nomComplet");      // ex. "RAKOTO Aina"
    String statutLibelle  = (String)  request.getAttribute("statutLibelle");   // ex. "SCAN TERMINÉ"
    Boolean verrouille    = Boolean.TRUE.equals(request.getAttribute("verrouille"));

    /* ── Pièces à scanner (List<Map>) ── */
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> pieces = (List<Map<String, Object>>) request.getAttribute("pieces");

    /* ── Badge couleur selon statut ── */
    String badgeClass = "badge-gray";
    String badgeLabel = statutLibelle != null ? statutLibelle : "Inconnu";
    if ("SCAN TERMINÉ".equalsIgnoreCase(badgeLabel))          badgeClass = "badge-violet";
    else if ("EN ATTENTE DE SCAN".equalsIgnoreCase(badgeLabel)) badgeClass = "badge-orange";
    else if ("EN COURS".equalsIgnoreCase(badgeLabel))           badgeClass = "badge-blue";
    else if ("ERREUR SCAN".equalsIgnoreCase(badgeLabel))        badgeClass = "badge-red";
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scan - <%= reference != null ? reference : "Demande" %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
</head>
<body>
<div class="container">

    <!-- ══ BANDEAU VERROUILLÉ ══════════════════════════════════════════ -->
    <% if (verrouille) { %>
    <div class="lock-banner" role="alert" aria-live="assertive">
        <span class="lock-icon"></span>
        Dossier verrouillé - plus aucune modification possible
    </div>
    <% } %>

    <!-- ══ EN-TÊTE ═════════════════════════════════════════════════════ -->
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

    <!-- ══ PROGRESSION GLOBALE ════════════════════════════════════════ -->
    <div class="form-section progress-section">
        <div class="progress-header">
            <span class="progress-label">Progression du scan</span>
            <span class="progress-count" id="progressCount">0 / 0 pièces</span>
        </div>
        <div class="progress-bar-track">
            <div class="progress-bar-fill" id="progressBarFill" style="width:0%"></div>
        </div>
    </div>

    <!-- ══ MESSAGE GLOBAL ════════════════════════════════════════════ -->
    <div id="globalMessage" class="hidden" role="alert" aria-live="assertive"></div>

    <!-- ══ LISTE DES PIÈCES À SCANNER ════════════════════════════════ -->
    <div class="form-section" id="piecesSection">
        <h2>Pièces justificatives</h2>

        <% if (pieces != null && !pieces.isEmpty()) { %>
        <div class="piece-list" id="pieceList">
            <% for (Map<String, Object> piece : pieces) {
                Long   pieceId     = piece.get("id")      != null ? Long.valueOf(String.valueOf(piece.get("id"))) : 0L;
                String pieceLibelle = piece.get("libelle") != null ? String.valueOf(piece.get("libelle")) : "-";
                String scanStatut  = piece.get("scanStatut") != null ? String.valueOf(piece.get("scanStatut")) : "EN_ATTENTE";
                String fileName    = piece.get("fileName")  != null ? String.valueOf(piece.get("fileName")) : "";
                boolean scanned    = "SCANNÉ".equalsIgnoreCase(scanStatut);
            %>
            <div class="piece-card <%= scanned ? "piece-card--done" : "" %>"
                 id="piece-<%= pieceId %>"
                 data-piece-id="<%= pieceId %>"
                 data-scanned="<%= scanned %>">

                <div class="piece-card__info">
                    <span class="piece-card__status-dot <%= scanned ? "dot--green" : "dot--gray" %>"></span>
                    <span class="piece-card__label"><%= pieceLibelle %></span>
                </div>

                <div class="piece-card__actions">
                    <% if (scanned) { %>
                        <span class="piece-card__filename"><%= fileName %></span>
                        <% if (!verrouille) { %>
                        <button type="button"
                                class="btn-alt btn-sm js-replace-btn"
                                data-piece-id="<%= pieceId %>">
                            Remplacer
                        </button>
                        <% } %>
                        <span class="badge badge-green badge-sm">Scanné</span>
                    <% } else { %>
                        <% if (!verrouille) { %>
                        <label class="btn btn-sm js-upload-label" data-piece-id="<%= pieceId %>">
                            <input type="file"
                                   class="js-file-input visually-hidden"
                                   accept=".pdf,.jpg,.jpeg,.png"
                                   data-piece-id="<%= pieceId %>"
                                   data-demande-id="<%= demandeId %>">
                            Importer le scan
                        </label>
                        <% } %>
                        <span class="badge badge-gray badge-sm">En attente</span>
                    <% } %>
                </div>

                <!-- Barre de progression upload individuelle -->
                <div class="piece-card__upload-progress hidden" id="upload-progress-<%= pieceId %>">
                    <div class="mini-progress-track">
                        <div class="mini-progress-fill"></div>
                    </div>
                    <span class="mini-progress-label">Envoi en cours…</span>
                </div>

                <!-- Zone d'erreur individuelle -->
                <div class="piece-card__error hidden" id="upload-error-<%= pieceId %>"></div>
            </div>
            <% } %>
        </div>
        <% } else { %>
        <p class="hint-text">Aucune pièce justificative associée à cette demande.</p>
        <% } %>
    </div>

    <!-- ══ ACTIONS GLOBALES ══════════════════════════════════════════ -->
    <div class="form-actions scan-actions">
        <% if (!verrouille) { %>
        <button type="button" id="finalizeScanBtn" class="btn-primary" disabled>
            Finaliser le scan
        </button>
        <% } %>
        <a href="<%= ctx %>/demande/<%= demandeId != null ? demandeId : "" %>" class="btn-alt">
            Retour au dossier
        </a>
    </div>

</div><!-- /container -->

<script src="<%= ctx %>/js/scanDemande.js"></script>
</body>
</html>
