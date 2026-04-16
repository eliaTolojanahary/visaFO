<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="models.Reservation" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat de la Réservation</title>
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
            padding: 15px;
            border-left: 4px solid #4CAF50;
            margin-bottom: 15px;
        }
        .info-label {
            font-weight: bold;
            color: #555;
        }
        .info-value {
            color: #333;
            margin-left: 10px;
        }
        .btn-back {
            background-color: #2196F3;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            text-decoration: none;
            display: inline-block;
            margin-top: 20px;
        }
        .btn-back:hover {
            background-color: #0b7dda;
        }
        .center {
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Résultat de la Réservation</h1>
        
        <% 
            Boolean success = (Boolean) request.getAttribute("success");
            Reservation reservation = (Reservation) request.getAttribute("reservation");
            String error = (String) request.getAttribute("error");
            
            if (success != null && success) {
        %>
            <div class="success">
                ✓ Réservation enregistrée avec succès !
            </div>
            
            <% if (reservation != null) { %>
                <div class="info">
                    <span class="info-label">N° Réservation:</span>
                    <span class="info-value"><%= reservation.getId() %></span>
                </div>
                <div class="info">
                    <span class="info-label">Client:</span>
                    <span class="info-value"><%= reservation.getClient() %></span>
                </div>
                <div class="info">
                    <span class="info-label">Nombre de passagers:</span>
                    <span class="info-value"><%= reservation.getNbPassager() %></span>
                </div>
                <div class="info">
                    <span class="info-label">Date et heure d'arrivée:</span>
                    <span class="info-value"><%= reservation.getDateHeureDepart() %></span>
                </div>
                <div class="info">
                    <span class="info-label">Hôtel (ID):</span>
                    <span class="info-value"><%= reservation.getIdHotel() %></span>
                </div>
            <% } %>
        <% 
            } else {
        %>
            <div class="error">
                ✗ Erreur lors de l'enregistrement de la réservation
                <% if (error != null) { %>
                    <br><%= error %>
                <% } %>
            </div>
        <% } %>
        
        <div class="center">
            <a href="<%= request.getContextPath() %>/reservation/form" class="btn-back">Nouvelle réservation</a>
        </div>
    </div>
</body>
</html>
