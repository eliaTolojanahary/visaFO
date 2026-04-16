<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Vehicule" %>
<%
    Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Modifier Véhicule</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .form-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #555;
            font-weight: bold;
        }
        input[type="text"],
        input[type="number"],
        input[type="hidden"],
        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        button {
            width: 100%;
            padding: 12px;
            background-color: #2196F3;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
        }
        button:hover {
            background-color: #0b7dda;
        }
        .back-link {
            display: block;
            text-align: center;
            margin-top: 20px;
            color: #666;
            text-decoration: none;
        }
        .back-link:hover {
            color: #333;
        }
        .error {
            color: red;
            text-align: center;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h1>Modifier le Véhicule</h1>
        
        <% if (request.getAttribute("error") != null) { %>
            <p class="error"><%= request.getAttribute("error") %></p>
        <% } %>
        
        <% if (vehicule != null) { %>
            <form action="update" method="post">
                <input type="hidden" name="id" value="<%= vehicule.getId() %>">
                
                <div class="form-group">
                    <label for="reference">Référence:</label>
                    <input type="text" id="reference" name="reference" value="<%= vehicule.getReference() %>" required>
                </div>
                
                <div class="form-group">
                    <label for="place">Nombre de Places:</label>
                    <input type="number" id="place" name="place" value="<%= vehicule.getPlace() %>" min="1" required>
                </div>
                
                <div class="form-group">
                    <label for="typeCarburant">Type de Carburant:</label>
                    <select id="typeCarburant" name="typeCarburant" required>
                        <option value="Essence" <%= "Essence".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Essence</option>
                        <option value="Diesel" <%= "Diesel".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Diesel</option>
                        <option value="Electrique" <%= "Electrique".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Electrique</option>
                        <option value="Hybride" <%= "Hybride".equals(vehicule.getTypeCarburant()) ? "selected" : "" %>>Hybride</option>
                    </select>
                </div>
                
                <button type="submit">Mettre à jour</button>
            </form>
        <% } else { %>
            <p class="error">Véhicule non trouvé</p>
        <% } %>
        
        <a href="list" class="back-link">← Retour à la liste</a>
    </div>
</body>
</html>
