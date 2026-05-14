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

    // dossierId – transmis par le controller ou extrait de la demande
    Long dossierId = null;
    if (request.getAttribute("dossierId") != null) {
        try { dossierId = Long.parseLong(String.valueOf(request.getAttribute("dossierId"))); }
        catch (Exception ignore) {}
    }
    String dossierIdValue = dossierId != null ? String.valueOf(dossierId) : "";
    
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
        scanPieces = listePiecesAttendues;
    } else if (pieces != null && !pieces.isEmpty()) {
        scanPieces = pieces;
    } else if (isCreationMode && piecesCommunes != null && !piecesCommunes.isEmpty()) {
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

    // Déterminer si la pièce "Signature numérique" (id=100) est déjà scannée
    boolean signatureDejaScannee = false;
    String signatureFileName = "";
    if (scanPieces != null) {
        for (Map<String, Object> p : scanPieces) {
            Object idObj = getMapValue(p, "pieceRefId", "piece_ref_id", "id");
            if (idObj != null && "100".equals(String.valueOf(idObj))) {
                String statut = String.valueOf(getMapValue(p, "scanStatut", "scan_statut", "statut"));
                signatureDejaScannee = "SCANNÉ".equalsIgnoreCase(statut) || "SCANNED".equalsIgnoreCase(statut);
                signatureFileName = String.valueOf(getMapValue(p, "fileName", "nom_fichier", "fichier"));
                break;
            }
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
    <style>
        /* ── Bloc Signature ────────────────────────────────────────────── */
        .signature-bloc {
            margin-top: 2rem;
            padding: 1.5rem;
            border: 1px solid var(--border-color, #d1d5db);
            border-radius: 0.5rem;
            background: var(--card-bg, #ffffff);
        }
        .signature-bloc h3 {
            margin: 0 0 1rem;
            font-size: 1rem;
            font-weight: 600;
            color: var(--text-primary, #111827);
        }
        .signature-canvas-wrapper {
            position: relative;
            border: 2px dashed var(--border-color, #d1d5db);
            border-radius: 0.375rem;
            background: #fafafa;
            cursor: crosshair;
            touch-action: none;
        }
        #signatureCanvas {
            display: block;
            width: 100%;
            height: 180px;
            border-radius: 0.375rem;
        }
        /* Texte indicatif via pseudo-element : jamais dans le flux d'evenements */
        .signature-canvas-wrapper::before {
            content: 'Signez ici avec la souris ou le doigt';
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            color: #9ca3af;
            font-size: 0.875rem;
            pointer-events: none;
            user-select: none;
            white-space: nowrap;
        }
        .signature-canvas-wrapper.has-drawing::before { display: none; }
        #signatureCanvas {
            display: block;
            width: 100%;
            height: 180px;
            border-radius: 0.375rem;
        }
        .signature-actions {
            display: flex;
            gap: 0.75rem;
            flex-wrap: wrap;
            margin-top: 0.75rem;
        }
        .signature-preview-wrapper {
            margin-top: 0.75rem;
        }
        .signature-preview-wrapper img {
            max-width: 300px;
            border: 1px solid var(--border-color, #d1d5db);
            border-radius: 0.25rem;
            background: #fff;
        }
        .signature-status {
            margin-top: 0.5rem;
            font-size: 0.875rem;
            min-height: 1.25rem;
        }
        .signature-status--success { color: #16a34a; }
        .signature-status--error   { color: #dc2626; }
        .signature-status--loading { color: var(--text-muted, #6b7280); font-style: italic; }
        .signature-already-done {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 0.75rem;
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
            border-radius: 0.375rem;
            font-size: 0.875rem;
            color: #15803d;
            margin-bottom: 0.75rem;
        }
    </style>
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

    <div class="completion-status">
        <div class="progress-container">
            <div class="progress-label">
                Progression: <span id="scannedCount">0</span> / <span id="totalCount">0</span> pieces
            </div>
            </br>
            <div class="progress-bar-track">
                <div class="progress-bar-fill" id="progressBarFill" style="width:0%"></div>
            </div>
        </div>
    </div>

    <div class="form-section">
        <h2>Pieces justificatives a scanner</h2>
        <% if (scanPieces != null && !scanPieces.isEmpty()) { %>
        <div class="piece-list" id="pieceList">
        <%
            for (Map<String, Object> piece : scanPieces) {
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

    <%-- ================================================================
         BLOC CAPTURE SIGNATURE (sprint 5)
         Visible uniquement en mode SCAN et si le dossier n'est pas verrouillé
         ================================================================ --%>
    <% if (isScanMode && !isCreationMode) { %>
    <div class="form-section">
        <h2>Capture Signature</h2>

        <div class="signature-bloc"
             id="signatureBloc"
             data-demande-id="<%= demandeIdValue %>"
             data-dossier-id="<%= dossierIdValue %>">

            <h3>Signature numérique du demandeur</h3>

            <% if (signatureDejaScannee) { %>
            <div class="signature-already-done">
                <span>✓</span>
                <span>Signature déjà enregistrée : <strong><%= signatureFileName %></strong></span>
            </div>
            <% } %>

            <% if (!isLocked) { %>
            <div class="signature-canvas-wrapper" id="signatureCanvasWrapper">
                <canvas id="signatureCanvas" aria-label="Zone de signature"></canvas>
            </div>

            <div class="signature-actions">
                <button type="button" class="btn-alt btn-sm" id="signatureBtnClear">
                    Effacer
                </button>
                <button type="button" class="btn-alt btn-sm" id="signatureBtnPreview">
                    Prévisualiser
                </button>
                <button type="button" class="btn-primary btn-sm" id="signatureBtnUpload">
                    <%= signatureDejaScannee ? "Remplacer la signature" : "Enregistrer la signature" %>
                </button>
            </div>

            <div class="signature-preview-wrapper">
                <img id="signaturePreview"
                     src=""
                     alt="Aperçu de la signature"
                     style="display:none;"
                     aria-live="polite">
            </div>

            <div id="signatureStatus" class="signature-status" aria-live="polite"></div>
            <% } else { %>
            <p class="hint-text">Le dossier est verrouillé — aucune modification possible.</p>
            <% } %>

        </div>
    </div>
    <% } %>

    <% if (!isCreationMode) { %>
    <div class="form-section">
        <h2>Finaliser le Scan</h2>
        <div class="completion-status">
            <div class="completion-message <%= demandeComplete ? "complete" : "incomplete" %>" id="completionMessage">
                <% if (demandeComplete) { %>
                <span class="icon">✓</span> Toutes les pieces attendues ont ete scannees. Vous pouvez maintenant verrouiller le dossier.
                <% } else { %>
                 Des pieces manquent encore. Le bouton sera active quand toutes les pieces seront scannees.
                <% } %>
            </div>
        </div>
            <!-- SECTION: Capture Photo d'Identité à la Webcam (Sprint 5) -->
            <% if (!isCreationMode && !isLocked) { %>
            <div class="form-section" id="photo-identite-block"
                data-demande-id="<%= demandeIdValue %>"
                data-dossier-id="<%= dossierIdValue %>">

                <h2>Capture Photo d'Identité (Webcam)</h2>
        
                <div class="camera-controls" style="margin-bottom: 15px;">
                    <button type="button" id="startCameraBtn" class="btn-primary btn-sm">
                        Démarrer la caméra
                    </button>
                    <button type="button" id="stopCameraBtn" class="btn-alt btn-sm" style="display:none;">
                        Arrêter la caméra
                    </button>
                </div>
        
                <div class="camera-container" style="display:none;">
                    <video id="cameraVideo" width="480" height="360" autoplay playsinline style="border: 2px solid #ddd; border-radius: 4px;"></video>
                </div>
        
                <div class="photo-capture-area" style="margin-top: 15px;">
                    <div class="capture-controls">
                        <button type="button" id="capturePhotoBtn" class="btn-secondary btn-sm" style="display:none;">Capturer photo</button>
                        <button type="button" id="retakeCameraBtn" class="btn-alt btn-sm" style="display:none;">Reprendre photo</button>
                    </div>
                    <div class="photo-preview-area" style="margin-top: 10px;">
                        <img id="photoPreview" style="max-width: 300px; max-height: 300px; border: 2px solid #ddd; border-radius: 4px; display:none;">
                    </div>
                </div>
        
                <div class="photo-upload-area" style="margin-top: 15px;">
                    <button type="button" id="uploadPhotoBtn" class="btn-success btn-sm" style="display:none;">Uploader cette photo</button>
                </div>
        
                <div id="photoUploadStatus" style="margin-top: 10px; padding: 10px; border-radius: 4px; display:none;"></div>
            </div>
            <% } %>
        
            <% if (!isCreationMode) { %>
            <div class="form-section">
                <h2>Finaliser le Scan</h2>
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
            <% } %>

    <div class="form-actions scan-actions">
        <a href="<%= ctx %>/dashboard" class="btn-alt">Retour au Dashboard</a>
    </div>
    <% } %>

</div>

<% if (!isCreationMode) { %>
<script src="<%= ctx %>/js/scanDemande.js"></script>
<script src="<%= ctx %>/js/signatureCanvas.js"></script>
<script src="<%= ctx %>/js/photoWebcam.js"></script>
<% } %>


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

</body>
</html>