<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<% String ctx = request.getContextPath(); %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Suivi du Dossier - Demande de Visa</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/suiviDossier.css">
</head>
<body>
<div class="container">
    <header>
        <h1>Suivi du Dossier - Demande de Visa</h1>
    </header>

    <%
        Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> piecesScannees = (List<Map<String, Object>>) request.getAttribute("piecesScannees");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> listePiecesAttendues = (List<Map<String, Object>>) request.getAttribute("listePiecesAttendues");
        String statutLibelle = (String) request.getAttribute("statutLibelle");
        Boolean isLocked = (Boolean) request.getAttribute("isLocked");
        String refDemande = demande != null && demande.get("ref_demande") != null ? String.valueOf(demande.get("ref_demande")) : "";
        
        if (isLocked == null) isLocked = false;
    %>

    <%-- ===== BLOC DOSSIER VERROUILLÉ ===== --%>
    <% if (isLocked) { %>
        <div class="locked-banner">
            <span class="icon icon-lock"></span>
            <div>
                <h2>Dossier Verrouillé</h2>
                <p>Ce dossier est verrouillé. Aucune modification n'est possible sur la demande, le demandeur ou le passeport.</p>
            </div>
        </div>
    <% } %>

    <%-- ===== BLOC INFORMATIONS DE LA DEMANDE ===== --%>
    <% if (demande != null) { %>
        <div class="info-section">
            <h2>Informations de la Demande</h2>
            
            <div class="demand-info">
                <div class="info-block">
                    <label>Référence de la demande</label>
                    <span><%= demande.get("ref_demande") != null ? demande.get("ref_demande") : "-" %></span>
                </div>
                
                <div class="info-block">
                    <label>Nom complet du demandeur</label>
                    <span><%= demande.get("nom") != null ? demande.get("nom") : "-" %> <%= demande.get("prenom") != null ? demande.get("prenom") : "" %></span>
                </div>
                
                <div class="info-block">
                    <label>Numéro de passeport</label>
                    <span><%= demande.get("numeroPasseport") != null ? demande.get("numeroPasseport") : "-" %></span>
                </div>
                
                <div class="info-block">
                    <label>Type de demande</label>
                    <span><%= demande.get("typeDemandeLibelle") != null ? demande.get("typeDemandeLibelle") : "-" %></span>
                </div>
                
                <div class="info-block">
                    <label>Type de titre</label>
                    <span><%= demande.get("typeTitreLibelle") != null ? demande.get("typeTitreLibelle") : "-" %></span>
                </div>
                
                <div class="info-block">
                    <label>Date de création</label>
                    <span><%= demande.get("createdAt") != null ? demande.get("createdAt") : "-" %></span>
                </div>
            </div>
            
            <div class="status-display">
                <strong>Statut actuel :</strong>
                <%
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

    <%-- ===== BLOC DOCUMENTS SCANNÉS ===== --%>
    <div class="documents-section">
        <h2>Documents Scannés</h2>
        
        <% if (piecesScannees != null && !piecesScannees.isEmpty()) { %>
            <ul class="documents-list">
                <% for (Map<String, Object> piece : piecesScannees) { %>
                    <li class="document-item">
                        <div class="document-info">
                            <div class="document-name"><%= piece.get("pieceLibelle") != null ? piece.get("pieceLibelle") : "Document" %></div>
                            <div class="document-file">
                                <span class="icon icon-file"></span>
                                <%= piece.get("nomFichier") != null ? piece.get("nomFichier") : "Fichier" %>
                            </div>
                            <% if (piece.get("tailleFichier") != null) { %>
                                <div class="document-file">
                                    <strong>Taille :</strong> <%= piece.get("tailleFichier") %> KB
                                </div>
                            <% } %>
                            <% if (piece.get("dateUpload") != null) { %>
                                <div class="document-file">
                                    <strong>Uploadé le :</strong> <%= piece.get("dateUpload") %>
                                </div>
                            <% } %>
                        </div>
                        <div class="document-actions">
                            <a href="<%= ctx %>/demande/<%= demande.get("demande_id") %>/piece/<%= piece.get("piece_ref_id") %>/download" class="btn-download">Télécharger</a>
                        </div>
                    </li>
                <% } %>
            </ul>
        <% } else { %>
            <div class="no-documents">
                <span class="icon icon-info"></span> Aucun document scanné pour l'instant
            </div>
        <% } %>
        
        <% if (!isLocked) { %>
            <div class="scan-actions">
                <a href="<%= ctx %>/demande/<%= demande != null && demande.get("demande_id") != null ? demande.get("demande_id") : "#" %>/scan" class="btn-primary">
                    Ajouter un scan
                </a>
            </div>
        <% } %>
    </div>

    <%-- ===== BLOC NAVIGATION ===== --%>
    <div class="info-section" style="text-align: center;">
        <a href="<%= ctx %>/form" class="btn-back">Retour au Dashboard</a>
    </div>

</div>
</body>
</html>