<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="models.PlanningConfig" %>
<%

    PlanningConfig planning_config= (PlanningConfig) request.getAttribute("config");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Configuration Paramètres Planning</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
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
        .info-box {
            background-color: #e7f3ff;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #2196F3;
        }
        .info-box h3 {
            margin-top: 0;
            color: #1976D2;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input[type="number"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        .unit {
            color: #888;
            font-size: 14px;
            margin-top: 5px;
        }
        .btn-submit {
            background-color: #4CAF50;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
        }
        .btn-submit:hover {
            background-color: #45a049;
        }
        .btn-secondary {
            background-color: #2196F3;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            text-decoration: none;
            display: inline-block;
            margin-top: 10px;
        }
        .btn-secondary:hover {
            background-color: #1976D2;
        }
        .error {
            color: red;
            margin-bottom: 15px;
            padding: 10px;
            background-color: #fee;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><span style="font-size:1.2em;vertical-align:middle;" class="material-icons">settings</span> Configuration des Paramètres Planning</h1>
        
        <% 
            if (planning_config!= null && planning_config.getId() > 0) {
        %>
            <div class="info-box">
                <h3>Configuration actuelle</h3>
                <p><strong>Vitesse moyenne :</strong> <%= planning_config.getVitesseMoyenne() %> km/h</p>
                <p><strong>Temps d'attente :</strong> <%= planning_config.getTempsAttente() %> minutes</p>
            </div>
        <% } %>
        
        <% if (request.getAttribute("error") != null) { %>
            <div class="error">
                <%= request.getAttribute("error") %>
            </div>
        <% } %>
        
        <form action="<%= request.getContextPath() %>/planning/config/save" method="POST">
            <div class="form-group">
                <label for="vitesseMoyenne">Vitesse Moyenne de Déplacement :</label>
                <input type="number" 
                       id="vitesseMoyenne" 
                       name="vitesseMoyenne" 
                       step="0.1" 
                       min="1" 
                       value="<%= planning_config != null ? planning_config.getVitesseMoyenne() : 40.0 %>" 
                       required>
                <div class="unit">En kilomètres par heure (km/h)</div>
            </div>
            
            <div class="form-group">
                <label for="tempsAttente">Temps d'Attente Standard :</label>
                <input type="number" 
                       id="tempsAttente" 
                       name="tempsAttente" 
                       min="0" 
                       value="<%= planning_config != null ? planning_config.getTempsAttente() : 15 %>" 
                       required>
                <div class="unit">En minutes</div>
            </div>
            
            <button type="submit" class="btn-submit"><span style="font-size:1.2em;vertical-align:middle;" class="material-icons">save</span> Enregistrer la Configuration</button>
        </form>
        
        <div style="text-align: center; margin-top: 20px;">
            <a href="<%= request.getContextPath() %>/planning/selection-date" class="btn-secondary">
                <span style="font-size:1.2em;vertical-align:middle;" class="material-icons">event</span> Aller à la sélection de date
            </a>
        </div>
    </div>
</body>
</html>
