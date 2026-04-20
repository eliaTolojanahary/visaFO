<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Map" %>
<%
    String cp = request.getContextPath();
    String error = (String) request.getAttribute("error");
    Map<String, String> validationErrors = (Map<String, String>) request.getAttribute("validationErrors");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Erreur formulaire visa</title>
    <style>
        body {
            margin: 0;
            min-height: 100vh;
            font-family: "Trebuchet MS", "Segoe UI", sans-serif;
            background: linear-gradient(135deg, #fef3f2, #fee4e2);
            color: #2f1a18;
            display: grid;
            place-items: center;
            padding: 18px;
        }
        .card {
            width: min(820px, 100%);
            background: #fff;
            border: 1px solid #f7c7c3;
            border-radius: 16px;
            box-shadow: 0 16px 34px rgba(103, 24, 13, 0.14);
            overflow: hidden;
        }
        .head {
            background: linear-gradient(120deg, #b42318, #d92d20);
            color: #fff;
            padding: 16px 20px;
        }
        .head h1 {
            margin: 0;
            font-size: 1.22rem;
        }
        .content {
            padding: 18px 20px;
        }
        .global {
            padding: 10px 12px;
            border-radius: 10px;
            border: 1px solid #fda29b;
            background: #fff4f2;
            color: #912018;
            margin-bottom: 14px;
        }
        .errors {
            margin: 0;
            padding: 0 0 0 18px;
            color: #7a271a;
        }
        .errors li {
            margin-bottom: 6px;
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
            cursor: pointer;
        }
        .primary {
            background: #0f766e;
        }
        .secondary {
            background: #475467;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="head">
            <h1>Validation echouee</h1>
        </div>
        <div class="content">
            <% if (error != null && !error.isEmpty()) { %>
                <div class="global"><%= error %></div>
            <% } %>

            <% if (validationErrors != null && !validationErrors.isEmpty()) { %>
                <h3>Details des champs a corriger</h3>
                <ul class="errors">
                    <% for (Map.Entry<String, String> entry : validationErrors.entrySet()) { %>
                        <li><strong><%= entry.getKey() %></strong> : <%= entry.getValue() %></li>
                    <% } %>
                </ul>
            <% } else { %>
                <p>Aucune erreur detaillee n'a ete fournie.</p>
            <% } %>

            <div class="actions">
                <a class="btn primary" href="<%= cp %>/visa/form">Revenir au formulaire</a>
                <a class="btn secondary" href="<%= cp %>/index.jsp">Accueil</a>
            </div>
        </div>
    </div>
</body>
</html>
