<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<% String ctx = request.getContextPath(); %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Gestion des Scans - Demande de Visa</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
</head>
<body>
<div class="container">
    <header>
        <h1>Gestion des Scans - Demande de Visa</h1>
    </header>

    <%
        Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> listePiecesAttendues = (List<Map<String, Object>>) request.getAttribute("listePiecesAttendues");
        Boolean demandeComplete = (Boolean) request.getAttribute("demandeComplete");
        String successMessage = (String) request.getAttribute("successMessage");
        String errorMessage = (String) request.getAttribute("errorMessage");
        Boolean isLocked = (Boolean) request.getAttribute("isLocked");
        
        if (demandeComplete == null) demandeComplete = false;
        if (isLocked == null) isLocked = false;
    %>

    <%-- ===== MESSAGES FLASH ===== --%>
    <% if (successMessage != null && !successMessage.isEmpty()) { %>
        <div class="flash-message flash-success">
            <span class="icon icon-success"></span> <%= successMessage %>
        </div>
    <% } %>
    <% if (errorMessage != null && !errorMessage.isEmpty()) { %>
        <div class="flash-message flash-error">
            <span class="icon icon-error"></span> <%= errorMessage %>
        </div>
    <% } %>

    <%-- ===== EN-TÊTE DEMANDE ===== --%>
    <% if (demande != null) { %>
        <div class="header-section">
            <div class="header-info">
                <div class="info-item">
                    <label>Référence de la demande</label>
                    <span><%= demande.get("ref_demande") != null ? demande.get("ref_demande") : "-" %></span>
                </div>
                <div class="info-item">
                    <label>Nom complet du demandeur</label>
                    <span><%= demande.get("nom") != null ? demande.get("nom") : "-" %> <%= demande.get("prenom") != null ? demande.get("prenom") : "" %></span>
                </div>
            </div>
            
            <div class="status-row">
                <strong>Statut actuel :</strong>
                <%
                    String statutLibelle = (String) request.getAttribute("statutLibelle");
                    String statusClass = "badge-gray";
                    if (statutLibelle != null && statutLibelle.equalsIgnoreCase("En cours de traitement")) statusClass = "badge-blue";
                    else if (statutLibelle != null && statutLibelle.equalsIgnoreCase("En attente")) statusClass = "badge-orange";
                    else if (statutLibelle != null && statutLibelle.equalsIgnoreCase("Valide")) statusClass = "badge-green";
                    else if (statutLibelle != null && statutLibelle.equalsIgnoreCase("Refuse")) statusClass = "badge-red";
                    else if (statutLibelle != null && statutLibelle.equalsIgnoreCase("SCAN TERMINÉ")) statusClass = "badge-purple";
                %>
                <span class="badge <%= statusClass %>"><%= statutLibelle != null ? statutLibelle : "-" %></span>
            </div>
        </div>
    <% } %>

    <%-- ===== BANDEAU DOSSIER VERROUILLÉ ===== --%>
    <% if (isLocked) { %>
        <div class="locked-banner">
            <span class="icon icon-lock"></span>
            <div>
                <h3>Dossier Verrouillé</h3>
                <p>Ce dossier est verrouillé. Plus aucune modification n'est possible sur la demande, le demandeur ou le passeport.</p>
            </div>
        </div>
    <% } %>

    <%-- ===== LISTE PIÈCES JUSTIFICATIVES ===== --%>
    <div class="pieces-section">
        <h2>Pièces Justificatives à Scanner</h2>
        
        <% if (listePiecesAttendues != null && !listePiecesAttendues.isEmpty()) { %>
            <% for (Map<String, Object> piece : listePiecesAttendues) { %>
                <div class="piece-item">
                    <div class="piece-title">
                        <%= piece.get("pieceLibelle") != null ? piece.get("pieceLibelle") : "Pièce" %>
                    </div>
                    
                    <%-- État du fichier --%>
                    <div class="piece-status">
                        <%
                            Map<String, Object> pieceFournie = (Map<String, Object>) piece.get("pieceFournie");
                            if (pieceFournie != null && pieceFournie.get("nomFichier") != null) {
                        %>
                            <div class="file-info">
                                <span class="icon icon-file"></span>
                                <strong>Fichier uploadé :</strong> <%= pieceFournie.get("nomFichier") %>
                            </div>
                            <% if (pieceFournie.get("tailleFichier") != null) { %>
                                <div class="file-info">
                                    <strong>Taille :</strong> <%= pieceFournie.get("tailleFichier") %> KB
                                </div>
                            <% } %>
                            <% if (pieceFournie.get("dateUpload") != null) { %>
                                <div class="file-info">
                                    <strong>Uploadé le :</strong> <%= pieceFournie.get("dateUpload") %>
                                </div>
                            <% } %>
                            <a href="<%= ctx %>/demande/<%= demande.get("demande_id") %>/piece/<%= piece.get("piece_ref_id") %>/download" class="btn-download">Télécharger</a>
                        <% } else { %>
                            <div class="no-file"><span class="icon icon-info"></span> Aucun fichier scanné</div>
                        <% } %>
                    </div>
                    
                    <%-- Formulaire upload --%>
                    <% if (!isLocked) { %>
                        <form action="<%= ctx %>/demande/<%= demande.get("demande_id") %>/piece/<%= piece.get("piece_ref_id") %>/upload" method="post" enctype="multipart/form-data" class="upload-form">
                            <div class="form-group">
                                <label for="file_<%= piece.get("piece_ref_id") %>">Sélectionner un fichier (JPEG, PNG, PDF - Max 10 Mo)</label>
                                <input type="file" id="file_<%= piece.get("piece_ref_id") %>" name="file" accept="image/jpeg,image/png,application/pdf" required>
                            </div>
                            <button type="submit" class="btn-upload">Uploader cette pièce</button>
                        </form>
                    <% } %>
                </div>
            <% } %>
        <% } else { %>
            <p class="no-pieces">Aucune pièce justificative à scanner pour cette demande.</p>
        <% } %>
    </div>

    <%-- ===== BLOC FINALISATION ===== --%>
    <div class="finalize-section">
        <h2>Finaliser le Scan</h2>
        
        <div class="completion-status">
            <div class="completion-message <%= demandeComplete ? "complete" : "incomplete" %>">
                <% if (demandeComplete) { %>
                    <span class="icon icon-check"></span> Toutes les pièces attendues ont été scannées. Vous pouvez maintenant verrouiller le dossier.
                <% } else { %>
                    <span class="icon icon-warning"></span> Des pièces manquent encore. Le bouton sera activé quand toutes les pièces seront scannées.
                <% } %>
            </div>
        </div>
        
        <% if (!isLocked) { %>
            <form action="<%= ctx %>/demande/<%= demande != null && demande.get("demande_id") != null ? demande.get("demande_id") : "#" %>/verrouiller" method="post" onsubmit="return confirm('Toutes les pièces sont scannées. Verrouiller définitivement le dossier ?');">
                <button type="submit" class="btn-finalize" <%= !demandeComplete ? "disabled" : "" %>>
                    Scan Terminé - Verrouiller le Dossier
                </button>
            </form>
        <% } %>
    </div>

    <%-- ===== NAVIGATION ===== --%>
    <div class="nav-section">
        <a href="<%= ctx %>/form" class="btn-back">Retour au Dashboard</a>
    </div>

</div>
</body>
</html>
