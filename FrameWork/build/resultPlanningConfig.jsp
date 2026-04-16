<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="models.PlanningConfig" %>
<!DOCTYPE html>
<html>
<head>
        <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <meta charset="UTF-8">
    <title>Résultat Configuration Planning</title>
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
        }
        .success {
            color: green;
            padding: 15px;
            background-color: #dff0d8;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
        }
        .error {
            color: red;
            padding: 15px;
            background-color: #fee;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
        }
        .result-box {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .result-item {
            margin-bottom: 10px;
        }
        .result-label {
            font-weight: bold;
            color: #555;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            margin: 5px;
            border-radius: 4px;
            text-decoration: none;
            text-align: center;
            cursor: pointer;
        }
        .btn-primary {
            background-color: #2196F3;
            color: white;
        }
        .btn-primary:hover {
            background-color: #1976D2;
        }
        .btn-secondary {
            background-color: #4CAF50;
            color: white;
        }
        .btn-secondary:hover {
            background-color: #45a049;
        }
        .button-group {
            text-align: center;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><span style="font-size:1.2em;vertical-align:middle;" class="material-icons">settings</span> Résultat de la Configuration</h1>
        
        <% 
            Boolean success = (Boolean) request.getAttribute("success");
            PlanningConfig planning_config= (PlanningConfig) request.getAttribute("config");
            String error = (String) request.getAttribute("error");
            
            if (success != null && success) {
        %>
            <div class="success">
                ✅ Configuration enregistrée avec succès !
            </div>
            
            <div class="result-box">
                <div class="result-item">
                    <span class="result-label">Vitesse Moyenne :</span> 
                    <%= planning_config.getVitesseMoyenne() %> km/h
                </div>
                <div class="result-item">
                    <span class="result-label">Temps d'Attente :</span> 
                    <%= planning_config.getTempsAttente() %> minutes
                </div>
            </div>
        <% } else { %>
            <div class="error">
                ❌ Erreur lors de l'enregistrement de la configuration
                <% if (error != null) { %>
                    <br><%= error %>
                <% } %>
            </div>
        <% } %>
        
        <div class="button-group">
            <a href="<%= request.getContextPath() %>/planning/config/form" class="btn btn-primary">
                <span style="font-size:1.2em;vertical-align:middle;" class="material-icons">settings</span> Modifier la configuration
            </a>
            <a href="<%= request.getContextPath() %>/planning/selection-date" class="btn btn-secondary">
                <span style="font-size:1.2em;vertical-align:middle;" class="material-icons">event</span> Sélection de date
            </a>
        </div>
    </div>
</body>
</html>
