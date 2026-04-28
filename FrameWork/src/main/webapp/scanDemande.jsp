﻿<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.PieceJustificative" %>

<%!
    // Helper pour extraire une valeur d'une Map avec fallback sur plusieurs clés
    private Object getMapValue(Map<String, Object> map, String... keys) {
        if (map == null) return null;
        for (String key : keys) {
            Object val = map.get(key);
            if (val != null) return val;
        }
        return null;
    }
%>

<%
    // ========================================
    // INITIALIZATION - All variables setup
    // ========================================
    String ctx = request.getContextPath();
    
    // Render layout flag: true = full HTML page, false = fragment only
    Object renderLayoutObj = request.getAttribute("renderLayout");
    boolean renderLayout = renderLayoutObj == null ? true : Boolean.parseBoolean(String.valueOf(renderLayoutObj));
    
    // Mode: SCAN (standalone), CREATION, UPDATE (embedded in form)
    String mode = request.getAttribute("mode") != null ? String.valueOf(request.getAttribute("mode")) : "SCAN";
    boolean isScanMode = "SCAN".equalsIgnoreCase(mode);
    boolean isCreationMode = "CREATION".equalsIgnoreCase(mode);
    
    // Demande information
    Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
    if (demande == null) demande = new HashMap<>();
    
    // Extract or fallback demande properties
    Long demandeId = null;
    if (request.getAttribute("demandeId") != null) {
        try { demandeId = Long.parseLong(String.valueOf(request.getAttribute("demandeId"))); } 
        catch (Exception ignore) {}
    } else if (demande.get("demande_id") != null) {
        try { demandeId = Long.parseLong(String.valueOf(demande.get("demande_id"))); } 
        catch (Exception ignore) {}
    }
    String demandeIdValue = demandeId != null ? String.valueOf(demandeId) : "";
    
    String reference = request.getAttribute("reference") != null ? String.valueOf(request.getAttribute("reference")) 
                     : (demande.get("ref_demande") != null ? String.valueOf(demande.get("ref_demande")) : "");
    
    String nomComplet = request.getAttribute("nomComplet") != null ? String.valueOf(request.getAttribute("nomComplet"))
                      : (demande.get("nom_complet") != null ? String.valueOf(demande.get("nom_complet")) : "");
    
    // Pieces lists
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> listePiecesAttendues = (List<Map<String, Object>>) request.getAttribute("listePiecesAttendues");
    
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> pieces = (List<Map<String, Object>>) request.getAttribute("pieces");
    
    @SuppressWarnings("unchecked")
    List<PieceJustificative> piecesCommunes = (List<PieceJustificative>) request.getAttribute("piecesCommunes");
    
    @SuppressWarnings("unchecked")
    List<PieceJustificative> piecesInvestisseur = (List<PieceJustificative>) request.getAttribute("piecesInvestisseur");
    
    @SuppressWarnings("unchecked")
    List<PieceJustificative> piecesTravailleur = (List<PieceJustificative>) request.getAttribute("piecesTravailleur");
    
    // Determine which pieces list to use
    List<Map<String, Object>> scanPieces = null;
    
    if (listePiecesAttendues != null && !listePiecesAttendues.isEmpty()) {
        // Mode SCAN ou DATA déjà préparée : utiliser directement
        scanPieces = listePiecesAttendues;
    } else if (pieces != null && !pieces.isEmpty()) {
        // Fallback sur pieces
        scanPieces = pieces;
    } else if (isCreationMode && piecesCommunes != null && !piecesCommunes.isEmpty()) {
        // [NEW] Mode CREATION sans données préparées : construire à partir de piecesCommunes
        scanPieces = new ArrayList<>();
        for (PieceJustificative p : piecesCommunes) {
            Map<String, Object> pieceMap = new HashMap<>();
            pieceMap.put("id", p.getId());
            pieceMap.put("libelle", p.getLibelle());
            pieceMap.put("scanStatut", "EN_ATTENTE");
            pieceMap.put("fileName", "");
            scanPieces.add(pieceMap);
        }
    }
    
    // Status flags
    Boolean demandeComplete = (Boolean) request.getAttribute("demandeComplete");
    if (demandeComplete == null) demandeComplete = false;
    
    Boolean isLocked = (Boolean) request.getAttribute("isLocked");
    if (isLocked == null) isLocked = (Boolean) request.getAttribute("verrouille");
    if (isLocked == null) isLocked = false;
    
    String flashMessage = (String) request.getAttribute("flashMessage");
    if (flashMessage == null) flashMessage = (String) request.getAttribute("successMessage");
    if (flashMessage == null) flashMessage = "";
    
    String flashError = (String) request.getAttribute("flashError");
    if (flashError == null) flashError = (String) request.getAttribute("errorMessage");
    if (flashError == null) flashError = "";
%>

<% if (renderLayout) { %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Scan - <%= reference.isEmpty() ? "Demande" : reference %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
</head>
<body>
<div class="container">

    <% if (!flashMessage.isEmpty()) { %>
    <div class="alert alert-success" role="alert">
        <%= flashMessage %>
    </div>
    <% } %>
    
    <% if (!flashError.isEmpty()) { %>
    <div class="alert alert-error" role="alert">
        <%= flashError %>
    </div>
    <% } %>

    <% if (isLocked) { %>
    <div class="lock-banner" role="alert">
        <span>Dossier verrouille - plus aucune modification possible</span>
    </div>
    <% } %>

    <div class="scan-header">
        <h1>Scan des pieces justificatives</h1>
        <div class="demande-info">
            <p><strong>Reference:</strong> <%= reference.isEmpty() ? "N/A" : reference %></p>
            <p><strong>Demandeur:</strong> <%= nomComplet.isEmpty() ? "N/A" : nomComplet %></p>
        </div>
    </div>

    <div class="progress-container">
        <div class="progress-label">
            Progression: <span id="scannedCount">0</span> / <span id="totalCount">0</span> pieces
        </div>
        <div class="progress-bar-track">
            <div class="progress-bar-fill" id="progressBarFill" style="width:0%"></div>
        </div>
    </div>

    <div class="form-section">
        <h2>Pieces justificatives a scanner</h2>
        <% if (scanPieces != null && !scanPieces.isEmpty()) { %>
        <div class="piece-list" id="pieceList">
        <%
            for (Map<String, Object> piece : scanPieces) {
                // Extraction tolérante camelCase / snake_case
                Long pieceId = null;
                Object idObj = getMapValue(piece, "pieceRefId", "piece_ref_id", "id");
                if (idObj != null) pieceId = Long.valueOf(String.valueOf(idObj));
                
                String libelle = String.valueOf(getMapValue(piece, "pieceLibelle", "libelle", "label"));
                String scanStatut = String.valueOf(getMapValue(piece, "scanStatut", "scan_statut", "statut"));
                String fileName = String.valueOf(getMapValue(piece, "fileName", "nom_fichier", "fichier"));
                
                boolean scanned = "SCANNÉ".equalsIgnoreCase(scanStatut) || "SCANNED".equalsIgnoreCase(scanStatut);
                String uploadUrl = ctx + "/demande/" + demandeIdValue + "/piece/" + pieceId + "/upload";
        %>
        <div class="piece-card <%= scanned ? "piece-card--done" : "" %>" id="piece-<%= pieceId %>">
            <div class="piece-card__info">
                <input type="checkbox" 
                       class="piece-card__checkbox js-piece-checkbox"
                       id="check-<%= pieceId %>"
                       data-piece-id="<%= pieceId %>"
                       name="piece_ids"
                       value="<%= pieceId %>"
                       <%= scanned ? "checked" : "" %>
                       <%= scanned ? "data-server-scanned=\"1\"" : "" %>>
                <label for="check-<%= pieceId %>" class="piece-card__checkbox-label">
                    <span class="piece-card__status-dot <%= scanned ? "dot--green" : "dot--gray" %>"></span>
                    <span class="piece-card__label"><%= libelle %></span>
                </label>
            </div>
            
            <div class="piece-card__right">
                <% if (scanned && !fileName.isEmpty() && !"null".equals(fileName)) { %>
                <div class="piece-card__file-meta">
                    <span class="piece-card__filename"><%= fileName %></span>
                    <span class="badge badge-green badge-sm">Scanned</span>
                </div>
                <% } else { %>
                <div class="piece-card__file-meta piece-card__file-meta--empty">
                    <span class="piece-card__no-file">Aucun fichier scanne</span>
                    <span class="badge badge-gray badge-sm">En attente</span>
                </div>
                <% } %>
                
                <% if (!isLocked && !isCreationMode) { %>
                <form class="piece-card__upload-form"
                      action="<%= uploadUrl %>"
                      method="post"
                      enctype="multipart/form-data"
                      novalidate
                      id="form-<%= pieceId %>"
                      <%= !scanned ? "style='display:none;'" : "" %>>
                    
                    <input type="hidden" name="pieceRefId" value="<%= pieceId %>">
                    <input type="hidden" name="demandeId" value="<%= demandeIdValue %>">
                    
                    <label class="piece-card__file-label" for="file-input-<%= pieceId %>">
                        <input type="file"
                               id="file-input-<%= pieceId %>"
                               name="fichier"
                               class="visually-hidden js-upload-input"
                               accept="image/jpeg,image/png,application/pdf"
                               required
                               data-piece-id="<%= pieceId %>">
                        <span class="piece-card__file-trigger btn-alt btn-sm">Choisir un fichier</span>
                        <span class="piece-card__file-chosen" id="chosen-<%= pieceId %>">Aucun fichier choisi</span>
                    </label>
                    
                    <button type="submit"
                            class="btn-sm piece-card__upload-btn js-upload-btn"
                            id="upload-btn-<%= pieceId %>"
                            data-piece-id="<%= pieceId %>"
                            disabled>
                        <%= scanned ? "Remplacer" : "Uploader cette piece" %>
                    </button>
                </form>
                <% } %>
            </div>
        </div>
        <% } %>
        </div>
        <% } else { %>
        <p class="hint-text">Aucune piece justificative associee a cette demande.</p>
        <% } %>
    </div>

    <% if (!isCreationMode) { %>
    <div class="form-section">
        <h2>Finaliser le Scan</h2>
        <div class="completion-status">
            <div class="completion-message <%= demandeComplete ? "complete" : "incomplete" %>">
                <% if (demandeComplete) { %>
                <span class="icon">✓</span> Toutes les pieces attendues ont ete scannees. Vous pouvez maintenant verrouiller le dossier.
                <% } else { %>
                 Des pieces manquent encore. Le bouton sera active quand toutes les pieces seront scannees.
                <% } %>
            </div>
        </div>
        
        <% if (!isLocked) { %>
        <form id="verrouillerForm"
              action="<%= ctx %>/demande/<%= demandeIdValue %>/verrouiller"
              method="post"
              style="display: inline;">
            <button type="submit" class="btn-primary" id="finalizeBtn" <%= !demandeComplete ? "disabled" : "" %>>
                Scan Termine - Verrouiller le Dossier
            </button>
        </form>
        <% } %>
    </div>

    <div class="form-actions scan-actions">
        <a href="<%= ctx %>/dashboard" class="btn-alt">Retour au Dashboard</a>
    </div>
    <% } %>

</div>

<% if (!isCreationMode) { %>
<script src="<%= ctx %>/js/scanDemande.js"></script>
<% } %>
</body>
</html>

<% } else { %>
<!-- FRAGMENT MODE: No HTML wrapper, just the form section -->
<div class="form-section">
    <h2>Pieces justificatives à selectionner</h2>

    <div class="progress-container">
        <div class="progress-label">
            Progression: <span id="scannedCount">0</span> / <span id="totalCount">0</span> pieces
        </div>
        <div class="progress-bar-track">
            <div class="progress-bar-fill" id="progressBarFill" style="width:0%"></div>
        </div>
    </div>
    
    <% if (scanPieces != null && !scanPieces.isEmpty()) { %>
    <div class="piece-list" id="pieceList">
    <%
        for (Map<String, Object> piece : scanPieces) {
            // Extraction tolérante camelCase / snake_case
            Long pieceId = null;
            Object idObj = getMapValue(piece, "pieceRefId", "piece_ref_id", "id");
            if (idObj != null) pieceId = Long.valueOf(String.valueOf(idObj));
            
            String libelle = String.valueOf(getMapValue(piece, "pieceLibelle", "libelle", "label"));
            String scanStatut = String.valueOf(getMapValue(piece, "scanStatut", "scan_statut", "statut"));
            
            boolean scanned = "SCANNÉ".equalsIgnoreCase(scanStatut) || "SCANNED".equalsIgnoreCase(scanStatut);
    %>
    <div class="piece-card <%= scanned ? "piece-card--done" : "" %>" id="piece-<%= pieceId %>">
        <div class="piece-card__info">
            <input type="checkbox" 
                   class="piece-card__checkbox js-piece-checkbox"
                   id="check-<%= pieceId %>"
                   data-piece-id="<%= pieceId %>"
                   name="piece_ids"
                   value="<%= pieceId %>"
                   <%= scanned ? "checked" : "" %>
                   <%= scanned ? "data-server-scanned=\"1\"" : "" %>>
            <label for="check-<%= pieceId %>" class="piece-card__checkbox-label">
                <span class="piece-card__status-dot <%= scanned ? "dot--green" : "dot--gray" %>"></span>
                <span class="piece-card__label"><%= libelle %></span>
            </label>
        </div>

        <div class="piece-card__right">
            <div class="piece-card__upload-form"
                 id="form-<%= pieceId %>"
                 <%= !scanned ? "style='display:none;'" : "" %>>
                <label class="piece-card__file-label" for="file-input-<%= pieceId %>">
                    <input type="file"
                           id="file-input-<%= pieceId %>"
                           name="piece_file_<%= pieceId %>"
                           class="visually-hidden scan-piece-input"
                           accept="image/jpeg,image/png,application/pdf"
                           data-piece-id="<%= pieceId %>">
                    <span class="piece-card__file-trigger btn-alt btn-sm">Choisir un fichier</span>
                    <span class="piece-card__file-chosen" id="chosen-<%= pieceId %>">Aucun fichier choisi</span>
                </label>
                <div class="piece-status" id="status-<%= pieceId %>">
                    <div class="no-file"><span class="icon icon-info"></span> Aucun fichier</div>
                </div>
            </div>
        </div>
    </div>
    <% } %>
    </div>
    <% } else { %>
    <p class="hint-text">Aucune piece justificative a afficher pour le moment.</p>
    <% } %>
</div>
<% } %>