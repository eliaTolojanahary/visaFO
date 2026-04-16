<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Vehicule" %>
<%
    Boolean success = (Boolean) request.getAttribute("success");
    Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
    String error = (String) request.getAttribute("error");
    String action = (String) request.getAttribute("action");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat - Véhicule</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .result-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .success-message {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
            border: 1px solid #c3e6cb;
        }
        .error-message {
            background-color: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
            border: 1px solid #f5c6cb;
        }
        .info-group {
            margin: 15px 0;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .info-label {
            font-weight: bold;
            color: #555;
            display: inline-block;
            width: 180px;
        }
        .info-value {
            color: #333;
        }
        .button-group {
            margin-top: 30px;
            display: flex;
            gap: 10px;
        }
        .btn {
            flex: 1;
            padding: 12px;
            text-decoration: none;
            text-align: center;
            border-radius: 4px;
            font-weight: bold;
            display: inline-block;
        }
        .btn-primary {
            background-color: #4CAF50;
            color: white;
        }
        .btn-primary:hover {
            background-color: #45a049;
        }
        .btn-secondary {
            background-color: #2196F3;
            color: white;
        }
        .btn-secondary:hover {
            background-color: #0b7dda;
        }
    </style>
</head>
<body>
    <div class="result-container">
        <h1>Résultat de l'Opération</h1>
        
        <% if (success != null && success) { %>
            <div class="success-message">
                <% if ("update".equals(action)) { %>
                    ✓ Le véhicule a été modifié avec succès!
                <% } else if ("delete".equals(action)) { %>
                    ✓ Le véhicule a été supprimé avec succès!
                <% } else { %>
                    ✓ Le véhicule a été enregistré avec succès!
                <% } %>
            </div>
            
            <% if (vehicule != null && !"delete".equals(action)) { %>
                <div class="info-group">
                    <span class="info-label">ID:</span>
                    <span class="info-value"><%= vehicule.getId() %></span>
                </div>
                <div class="info-group">
                    <span class="info-label">Référence:</span>
                    <span class="info-value"><%= vehicule.getReference() %></span>
                </div>
                <div class="info-group">
                    <span class="info-label">Nombre de Places:</span>
                    <span class="info-value"><%= vehicule.getPlace() %></span>
                </div>
                <div class="info-group">
                    <span class="info-label">Type de Carburant:</span>
                    <span class="info-value"><%= vehicule.getTypeCarburant() %></span>
                </div>
            <% } %>
        <% } else { %>
            <div class="error-message">
                ✗ Une erreur s'est produite lors de l'opération.
                <% if (error != null) { %>
                    <br><br><%= error %>
                <% } %>
            </div>
        <% } %>
        
        <div class="button-group">
            <a href="form" class="btn btn-primary">Ajouter un véhicule</a>
            <a href="list" class="btn btn-secondary">Voir la liste</a>
        </div>
    </div>
</body>
</html>
