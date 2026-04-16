<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.Vehicule" %>
<%@ page import="models.VehiclePlanningDTO" %>
<%@ page import="controllers.PlanningController.EtapeItineraire" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Détails du Véhicule / Antsipirian'ny Fiara</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 50px; 
            background-color: #f4f4f4; 
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background-color: white; 
            padding: 30px; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        h1, h2 { 
            color: #333; 
            text-align: center; 
        }
        .malagasy { 
            color: #1976D2; 
            font-size: 13px; 
            font-style: italic; 
        }
        .francais { 
            color: #555; 
            font-size: 14px; 
        }
        .info-section {
            background-color: #E3F2FD;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 30px;
            border-left: 5px solid #2196F3;
        }
        .info-section h3 {
            margin-top: 0;
            color: #1976D2;
        }
        .info-row {
            display: flex;
            margin-bottom: 10px;
        }
        .info-label {
            font-weight: bold;
            min-width: 200px;
            color: #333;
        }
        .info-value {
            color: #555;
        }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin-bottom: 20px; 
        }
        th, td { 
            padding: 12px; 
            text-align: left; 
            border-bottom: 1px solid #ddd; 
            vertical-align: middle; 
        }
        th { 
            background-color: #2196F3; 
            color: white; 
            font-weight: bold; 
        }
        tr:hover { 
            background-color: #f5f5f5; 
        }
        tr.retour-aeroport {
            background-color: #FFF3E0;
            font-weight: bold;
        }
        tr.retour-aeroport:hover {
            background-color: #FFE0B2;
        }
        .distance-badge {
            display: inline-block;
            padding: 5px 10px;
            background-color: #4CAF50;
            color: white;
            border-radius: 15px;
            font-weight: bold;
            font-size: 13px;
        }
        .total-distance {
            background-color: #FFF9C4;
            padding: 20px;
            border-radius: 5px;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            margin-top: 20px;
            border: 2px solid #FBC02D;
        }
        .total-distance .value {
            font-size: 32px;
            color: #F57C00;
            display: block;
            margin: 10px 0;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background-color: #2196F3;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
            transition: background-color 0.3s;
        }
        .btn:hover {
            background-color: #1976D2;
        }
        .error {
            background-color: #FFEBEE;
            color: #C62828;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 5px solid #C62828;
        }
        .etape-number {
            display: inline-block;
            width: 30px;
            height: 30px;
            background-color: #2196F3;
            color: white;
            border-radius: 50%;
            text-align: center;
            line-height: 30px;
            font-weight: bold;
        }
        .arrow {
            color: #666;
            font-size: 18px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Détails du Véhicule / <span class="malagasy">Antsipirian'ny Fiara</span></h1>
        
        <% String error = (String) request.getAttribute("error");
           if (error != null) { %>
            <div class="error"><%= error %></div>
        <% } %>
        
        <% Vehicule vehicule = (Vehicule) request.getAttribute("vehicule");
           VehiclePlanningDTO planning = (VehiclePlanningDTO) request.getAttribute("planning");
           List<EtapeItineraire> itineraire = (List<EtapeItineraire>) request.getAttribute("itineraire");
           Double distanceTotale = (Double) request.getAttribute("distanceTotale");
           String datePlanning = (String) request.getAttribute("datePlanning");
           
           if (vehicule != null) { %>
            
            <div class="info-section">
                <h3>Informations du Véhicule / <span class="malagasy">Mombamomba ny Fiara</span></h3>
                <div class="info-row">
                    <div class="info-label">ID Véhicule / <span class="malagasy">ID Fiara</span>:</div>
                    <div class="info-value"><%= vehicule.getId() %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Référence / <span class="malagasy">Référence</span>:</div>
                    <div class="info-value"><%= vehicule.getReference() %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Nombre de places / <span class="malagasy">Isan'ny toerana</span>:</div>
                    <div class="info-value"><%= vehicule.getPlace() %> places</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Type de carburant / <span class="malagasy">Karazana solika</span>:</div>
                    <div class="info-value"><%= vehicule.getTypeCarburant() %></div>
                </div>
                <% if (planning != null) { %>
                <div class="info-row">
                    <div class="info-label">Heure de départ / <span class="malagasy">Ora fiaingana</span>:</div>
                    <div class="info-value"><%= planning.getDateHeureDepart() %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Heure de retour / <span class="malagasy">Ora fiverenana</span>:</div>
                    <div class="info-value"><%= planning.getDateHeureRetour() %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Places occupées / <span class="malagasy">Toerana feno</span>:</div>
                    <div class="info-value"><%= planning.getPlacesOccupees() %> / <%= planning.getPlacesTotales() %></div>
                </div>
                <% } %>
            </div>
            
            <% if (itineraire != null && !itineraire.isEmpty()) { %>
            <h2>Itinéraire détaillé / <span class="malagasy">Lalam-pandehanana amin'ny antsipirihany</span></h2>
            <table>
                <thead>
                    <tr>
                        <th>Étape<br/><span class="malagasy">Dingana</span></th>
                        <th>Trajet<br/><span class="malagasy">Lalana</span></th>
                        <th>Distance (km)<br/><span class="malagasy">Halavirana</span></th>
                        <th>Heure d'arrivée<br/><span class="malagasy">Ora fahatongavana</span></th>
                        <th>Client<br/><span class="malagasy">Mpanjifa</span></th>
                        <th>Passagers<br/><span class="malagasy">Mpandeha</span></th>
                    </tr>
                </thead>
                <tbody>
                    <% for (EtapeItineraire etape : itineraire) { 
                        boolean isRetour = etape.getNomClient().equals("Retour aéroport");
                    %>
                        <tr <%= isRetour ? "class='retour-aeroport'" : "" %>>
                            <td>
                                <span class="etape-number"><%= etape.getOrdre() %></span>
                            </td>
                            <td>
                                <%= etape.getLieuDepart() %> 
                                <span class="arrow">→</span> 
                                <%= etape.getLieuArrivee() %>
                            </td>
                            <td>
                                <span class="distance-badge"><%= String.format("%.2f", etape.getDistance()) %> km</span>
                            </td>
                            <td><%= etape.getHeureArrivee() %></td>
                            <td>
                                <% if (!isRetour) { %>
                                    <strong><%= etape.getNomClient() %></strong>
                                <% } else { %>
                                    <em style="color: #FF6F00;">Retour aéroport / <span class="malagasy">Miverina amin'ny aéroport</span></em>
                                <% } %>
                            </td>
                            <td>
                                <% if (!isRetour) { %>
                                    <%= etape.getNbPassager() %> passager(s)
                                <% } else { %>
                                    -
                                <% } %>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
            
            <% if (distanceTotale != null) { %>
            <div class="total-distance">
                <div class="francais">Distance totale parcourue</div>
                <div class="malagasy">Halaviran-dalana rehetra</div>
                <span class="value"><%= String.format("%.2f", distanceTotale) %> km</span>
            </div>
            <% } %>
            <% } else { %>
            <div style="text-align: center; padding: 40px; color: #666;">
                <p>Aucun itinéraire disponible pour ce véhicule.</p>
                <p class="malagasy">Tsy misy lalam-pandehanana ho an'ity fiara ity.</p>
            </div>
            <% } %>
            
        <% } %>
        
        <div style="text-align: center;">
            <form action="<%= request.getContextPath() %>/planning/result" method="post" style="display: inline;">
                <input type="hidden" name="datePlanning" value="<%= datePlanning != null ? datePlanning : "" %>">
                <button type="submit" class="btn">
                    ← Retour à la planification / <span class="malagasy">Miverina amin'ny fandaminana</span>
                </button>
            </form>
        </div>
    </div>
</body>
</html>
