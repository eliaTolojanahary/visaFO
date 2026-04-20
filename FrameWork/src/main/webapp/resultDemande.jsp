<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="models.Demande" %>
<%
    String cp = request.getContextPath();
    Boolean success = (Boolean) request.getAttribute("success");
    String message = (String) request.getAttribute("message");
    String action = (String) request.getAttribute("action");
    Demande demande = (Demande) request.getAttribute("demande");

    boolean ok = success != null && success;
    boolean isUpdate = "update".equals(action);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultat Demande Visa</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 700px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 20px;
        }
        .success {
            color: green;
            padding: 15px;
            background-color: #dfd;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: bold;
        }
        .error {
            color: red;
            padding: 15px;
            background-color: #fee;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: bold;
        }
        .info {
            background-color: #f9f9f9;
            padding: 12px;
            border-left: 4px solid #4CAF50;
            margin-bottom: 10px;
        }
        .info-label {
            font-weight: bold;
            color: #555;
        }
        .info-value {
            color: #333;
            margin-left: 8px;
        }
        .actions {
            margin-top: 20px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            justify-content: center;
        }
        .btn {
            text-decoration: none;
            color: white;
            border-radius: 4px;
            padding: 12px 20px;
            font-weight: bold;
            display: inline-block;
        }
        .btn-primary {
            background-color: #4CAF50;
        }
        .btn-primary:hover {
            background-color: #45a049;
        }
        .btn-secondary {
            background-color: #2196F3;
        }
        .btn-secondary:hover {
            background-color: #0b7dda;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Resultat de la Demande Visa</h1>

        <% if (ok) { %>
            <div class="success">Operation reussie</div>
        <% } else { %>
            <div class="error">Operation en echec</div>
        <% } %>

        <% if (message != null && !message.isEmpty()) { %>
            <div class="info">
                <span class="info-label">Message:</span>
                <span class="info-value"><%= message %></span>
            </div>
        <% } else if (isUpdate) { %>
            <div class="info">
                <span class="info-label">Message:</span>
                <span class="info-value">Mise a jour traitee.</span>
            </div>
        <% } %>

        <% if (demande != null) { %>
            <div class="info"><span class="info-label">Demande ID:</span><span class="info-value"><%= demande.getId() %></span></div>
            <div class="info"><span class="info-label">Type titre:</span><span class="info-value"><%= (demande.getType_titre() != null ? demande.getType_titre().getLibelle() : "-") %></span></div>
            <div class="info"><span class="info-label">Type demande:</span><span class="info-value"><%= (demande.getType_demande() != null ? demande.getType_demande().getLibelle() : "-") %></span></div>
            <div class="info"><span class="info-label">Statut:</span><span class="info-value"><%= (demande.getStatut() != null ? demande.getStatut().getLibelle() : "-") %></span></div>
            <div class="info"><span class="info-label">Date entree visa:</span><span class="info-value"><%= demande.getVisa_date_entree() %></span></div>
            <div class="info"><span class="info-label">Date expiration visa:</span><span class="info-value"><%= demande.getVisa_date_expiration() %></span></div>
            <div class="info"><span class="info-label">Lieu entree:</span><span class="info-value"><%= demande.getVisa_lieu_entree() %></span></div>
        <% } %>

        <div class="actions">
            <a href="<%= cp %>/visa/form" class="btn btn-primary">Nouvelle demande</a>
            <a href="<%= cp %>/index.jsp" class="btn btn-secondary">Accueil</a>
        </div>
    </div>
</body>
</html>
