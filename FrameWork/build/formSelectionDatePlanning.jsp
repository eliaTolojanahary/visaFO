<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="models.PlanningConfig" %>
<%
    PlanningConfig planning_config= (PlanningConfig) request.getAttribute("config");
%>
<!DOCTYPE html>
<html>
<head>
        <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <meta charset="UTF-8">
    <title>Sélection Date de Planification</title>
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
            margin-bottom: 30px;
        }
        .config-info {
            background-color: #e8f5e9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 30px;
            border-left: 4px solid #4CAF50;
        }
        .config-info h3 {
            margin-top: 0;
            color: #2E7D32;
        }
        .config-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }
        .form-group {
            margin-bottom: 25px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #555;
            font-size: 16px;
        }
        input[type="date"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 16px;
        }
        input[type="date"]:focus {
            border-color: #2196F3;
            outline: none;
        }
        .btn-submit {
            background-color: #2196F3;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 18px;
            width: 100%;
            font-weight: bold;
        }
        .btn-submit:hover {
            background-color: #1976D2;
        }
        .btn-config {
            background-color: #FF9800;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            text-decoration: none;
            display: inline-block;
            margin-top: 15px;
        }
        .btn-config:hover {
            background-color: #F57C00;
        }
        .error {
            color: red;
            margin-bottom: 15px;
            padding: 10px;
            background-color: #fee;
            border-radius: 4px;
        }
        .info-text {
            color: #666;
            font-size: 14px;
            margin-top: 10px;
            text-align: center;
        }
        .links {
            text-align: center;
            margin-top: 20px;
        }
    </style>
    <script>
        // Définir la date du jour par défaut
        window.onload = function() {
            var today = new Date().toISOString().split('T')[0];
            document.getElementById('datePlanning').value = today;
        }
    </script>
</head>
<body>
    <div class="container">
        <h1><span class="material-icons" style="font-size:1.2em;vertical-align:middle;">event</span> Sélection de Date pour Planification</h1>
        
        <% 
            if (planning_config != null && planning_config.getId() > 0) {
        %>
            <div class="config-info">
                <h3><span class="material-icons" style="font-size:1.2em;vertical-align:middle;">settings</span> Configuration Active</h3>
                <div class="config-item">
                    <span><strong>Vitesse Moyenne :</strong></span>
                    <span><%= planning_config.getVitesseMoyenne() %> km/h</span>
                </div>
                <div class="config-item">
                    <span><strong>Temps d'Attente :</strong></span>
                    <span><%= planning_config.getTempsAttente() %> minutes</span>
                </div>
            </div>
        <% } %>
        
        <% if (request.getAttribute("error") != null) { %>
            <div class="error">
                <%= request.getAttribute("error") %>
            </div>
        <% } %>
        
        <form action="<%= request.getContextPath() %>/planning/result" method="POST">
            <div class="form-group">
                <label for="datePlanning"><span style="font-size:1.2em;vertical-align:middle;" class="material-icons">event</span> Sélectionnez la date de planification :</label>
                <input type="date" 
                       id="datePlanning" 
                       name="datePlanning" 
                       required>
                <div class="info-text">
                    Cliquez sur "Valider" pour lancer la planification
                </div>
            </div>
            
            <button type="submit" class="btn-submit">
                <span style="font-size:1.2em;vertical-align:middle;" class="material-icons">search</span> Valider et Lancer la Planification
            </button>
        </form>
        
        <div class="links">
            <a href="<%= request.getContextPath() %>/planning/config/form" class="btn-config">
                <span style="font-size:1.2em;vertical-align:middle;" class="material-icons">settings</span> Modifier les Paramètres Système
            </a>
        </div>
    </div>
</body>
</html>
