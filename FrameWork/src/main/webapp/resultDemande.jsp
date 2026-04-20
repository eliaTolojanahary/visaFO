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
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Resultat demande visa</title>
    <style>
        body {
            margin: 0;
            min-height: 100vh;
            font-family: "Trebuchet MS", "Segoe UI", sans-serif;
            background: linear-gradient(145deg, #e6f8f4, #daf4ee);
            display: grid;
            place-items: center;
            padding: 20px;
            color: #1c3130;
        }
        .card {
            width: min(760px, 100%);
            border-radius: 16px;
            background: #fff;
            border: 1px solid #afe3d8;
            box-shadow: 0 16px 38px rgba(7, 61, 56, 0.14);
            overflow: hidden;
        }
        .head {
            padding: 16px 20px;
            color: #fff;
            background: linear-gradient(120deg, #0f766e, #115e59);
        }
        .head.fail {
            background: linear-gradient(120deg, #b42318, #d92d20);
        }
        .head h1 {
            margin: 0;
            font-size: 1.2rem;
        }
        .content {
            padding: 18px 20px;
        }
        .pill {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 999px;
            font-size: 0.84rem;
            font-weight: 700;
            margin-bottom: 10px;
        }
        .ok {
            background: #dcfae6;
            color: #166534;
        }
        .ko {
            background: #fee4e2;
            color: #912018;
        }
        .grid {
            margin-top: 12px;
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 8px 14px;
        }
        .item {
            padding: 8px;
            border-radius: 8px;
            background: #f7fffd;
            border: 1px solid #d5f4ec;
        }
        .actions {
            margin-top: 16px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .btn {
            text-decoration: none;
            border: 0;
            border-radius: 10px;
            padding: 10px 14px;
            font-weight: 700;
            color: #fff;
        }
        .primary {
            background: #0f766e;
        }
        .secondary {
            background: #475467;
        }

        @media (max-width: 620px) {
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
<div class="card">
    <div class="head <%= ok ? "" : "fail" %>">
        <h1><%= ok ? "Operation terminee" : "Operation en echec" %></h1>
    </div>
    <div class="content">
        <span class="pill <%= ok ? "ok" : "ko" %>"><%= ok ? "SUCCES" : "ECHEC" %></span>

        <p>
            <%= (message != null && !message.isEmpty())
                ? message
                : (isUpdate ? "Mise a jour traitee." : "Enregistrement traite.") %>
        </p>

        <% if (demande != null) { %>
            <div class="grid">
                <div class="item"><strong>Demande ID:</strong> <%= demande.getId() %></div>
                <div class="item"><strong>Type titre:</strong> <%= (demande.getType_titre() != null ? demande.getType_titre().getLibelle() : "-") %></div>
                <div class="item"><strong>Type demande:</strong> <%= (demande.getType_demande() != null ? demande.getType_demande().getLibelle() : "-") %></div>
                <div class="item"><strong>Statut:</strong> <%= (demande.getStatut() != null ? demande.getStatut().getLibelle() : "-") %></div>
                <div class="item"><strong>Date entree visa:</strong> <%= demande.getVisa_date_entree() %></div>
                <div class="item"><strong>Date expiration visa:</strong> <%= demande.getVisa_date_expiration() %></div>
                <div class="item"><strong>Lieu entree:</strong> <%= demande.getVisa_lieu_entree() %></div>
            </div>
        <% } %>

        <div class="actions">
            <a class="btn primary" href="<%= cp %>/visa/form">Nouvelle saisie</a>
            <a class="btn secondary" href="<%= cp %>/index.jsp">Accueil</a>
        </div>
    </div>
</div>
</body>
</html>
