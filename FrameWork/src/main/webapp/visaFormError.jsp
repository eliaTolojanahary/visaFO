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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Erreur Formulaire Visa</title>
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
        .error {
            color: red;
            padding: 12px;
            background-color: #fee;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        ul {
            margin: 0;
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
            color: #555;
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
        <h1>Erreurs de validation</h1>

        <% if (error != null && !error.isEmpty()) { %>
            <div class="error"><%= error %></div>
        <% } %>

        <% if (validationErrors != null && !validationErrors.isEmpty()) { %>
            <div class="error">
                <strong>Champs a corriger:</strong>
                <ul>
                    <% for (Map.Entry<String, String> entry : validationErrors.entrySet()) { %>
                        <li><strong><%= entry.getKey() %></strong>: <%= entry.getValue() %></li>
                    <% } %>
                </ul>
            </div>
        <% } %>

        <div class="actions">
            <a href="<%= cp %>/visa/form" class="btn btn-primary">Retour au formulaire</a>
            <a href="<%= cp %>/index.jsp" class="btn btn-secondary">Accueil</a>
        </div>
    </div>
</body>
</html>
