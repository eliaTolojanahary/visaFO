<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Formulaire de Réservation</title>
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
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input[type="text"],
        input[type="number"],
        input[type="datetime-local"],
        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
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
        <h1>Formulaire de Réservation</h1>
        
        <% if (request.getAttribute("error") != null) { %>
            <div class="error">
                <%= request.getAttribute("error") %>
            </div>
        <% } %>
        
        <form action="<%= request.getContextPath() %>/reservation/save" method="POST">
                        <input type="hidden" name="id" value="0">
            
            <div class="form-group">
                <label for="client">Client:</label>
                <input type="text" id="client" name="client" placeholder="Ex: CL0001" required>
            </div>
            
            <div class="form-group">
                <label for="nbPassager">Nombre de passagers:</label>
                <input type="number" id="nbPassager" name="nbPassager" min="1" placeholder="Ex: 2" required>
            </div>
            
            <div class="form-group">
                <label for="dateHeureDepart">Date et heure d'arrivée:</label>
                <input type="datetime-local" id="dateHeureDepart" name="dateHeureDepart" required>
            </div>
            
            <div class="form-group">
                <label for="idHotel">Destination:</label>
                <select id="idHotel" name="idHotel" required>
                    <option value="">-- Choisir un lieu --</option>
                    <% 
                        List<Lieu> lieux = (List<Lieu>) request.getAttribute("lieux");
                        if (lieux != null) {
                            for (Lieu lieu : lieux) {
                    %>
                        <option value="<%= lieu.getId() %>"><%= lieu.getLibelle() %></option>
                    <% 
                            }
                        }
                    %>
                </select>
            </div>
            
            <button type="submit" class="btn-submit">Valider</button>
        </form>
    </div>
</body>
</html>
