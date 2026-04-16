<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.ReservationDTO" %>
<%@ page import="models.Vehicule" %>
<%@ page import="models.VehiclePlanningDTO" %>
<%@ page import="models.ClientInfo" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat de la Planification / Vokatra Planification</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background-color: #f4f4f4; }
        .container { max-width: 1100px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2 { color: #333; text-align: center; }
        .table-section { margin-bottom: 40px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #2196F3; color: white; font-weight: bold; }
        tr:hover { background-color: #f5f5f5; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
        .badge-unassigned { background-color: #FFF3CD; color: #856404; }
        .badge-assigned { background-color: #C8E6C9; color: #2E7D32; }
        .malagasy { color: #1976D2; font-size: 14px; font-style: italic; }
        .francais { color: #555; font-size: 14px; }
        .client-list { list-style-type: none; padding: 0; margin: 0; }
        .client-list li { padding: 5px 0; border-bottom: 1px dotted #ccc; }
        .client-list li:last-child { border-bottom: none; }
        .client-name { font-weight: bold; color: #333; }
        .client-details { font-size: 12px; color: #666; }
        .vehicle-id { font-weight: bold; color: #2196F3; }
        .vehicle-id-link { 
            background: none; 
            border: none; 
            color: #2196F3; 
            text-decoration: underline; 
            cursor: pointer; 
            font-weight: bold; 
            font-size: 14px; 
            padding: 0; 
        }
        .vehicle-id-link:hover { color: #1976D2; }
        .pagination { display: flex; justify-content: center; margin-bottom: 20px; flex-wrap: wrap; gap: 10px; }
        .page-btn { background-color: #f1f1f1; border: 1px solid #ccc; padding: 8px 16px; cursor: pointer; border-radius: 4px; font-weight: bold; }
        .page-btn.active { background-color: #2196F3; color: white; border-color: #2196F3; }
        .page-btn.active.immediate-dept { background-color: #d32f2f; border-color: #d32f2f; }
        .page-btn:hover:not(.active) { background-color: #ddd; }
        .creneau-section { display: none; }
        .creneau-section.active { display: block; }
    </style>
    <script>
        function showCreneau(creneauId) {
            // Hide all sections
            document.querySelectorAll('.creneau-section').forEach(function(el) {
                el.classList.remove('active');
            });
            // Remove active class from buttons
            document.querySelectorAll('.page-btn').forEach(function(el) {
                el.classList.remove('active');
            });
            // Show the selected section
            document.getElementById('section-' + creneauId).classList.add('active');
            // Add active class to clicked button
            document.getElementById('btn-' + creneauId).classList.add('active');
        }
    </script>
</head>
<body>
    <header>
        
    </header>
    <div class="container">
    <li>
            <ul>
                ETU003132
            </ul>
            <ul>
                ETU003230
            </ul>
            <ul>
                ETU003200
            </ul>
        </li>
        <h1>Résultat de la Planification / <span class="malagasy">Vokatra Planification</span></h1>
        
        <% String error = (String) request.getAttribute("error");
           if (error != null && !error.isEmpty()) { %>
            <div style="background-color: #f8d7da; color: #721c24; padding: 15px; margin-bottom: 20px; border: 1px solid #f5c6cb; border-radius: 4px;">
                <strong>Erreur : </strong> <%= error %>
            </div>
        <% } %>

        <% 
           Map<String, List<VehiclePlanningDTO>> planningsParCreneauMap = (Map<String, List<VehiclePlanningDTO>>) request.getAttribute("planningsParCreneauMap");
           Map<String, List<ReservationDTO>> unassignedParCreneauMap = (Map<String, List<ReservationDTO>>) request.getAttribute("unassignedParCreneauMap");
           String datePlanning = (String) request.getAttribute("datePlanning");

           if (planningsParCreneauMap != null && !planningsParCreneauMap.isEmpty()) { 
               int index = 0;
        %>
        
        <div class="pagination">
            <% for (String creneau : planningsParCreneauMap.keySet()) { 
                  String safeId = creneau.replace(":", "").replace(" ", "").replace("-", "_");
                  
                  boolean isImmediate = false;
                  String displayCreneau = creneau;
                  
                  if (creneau.contains("-")) {
                       String[] parts = creneau.split("-");
                       if (parts.length >= 2) {
                           String start = parts[0].trim();
                           String endPart = parts[1].trim(); 
                           boolean hasSuffix = endPart.contains("(");
                           String realEnd = hasSuffix ? endPart.substring(0, endPart.indexOf("(")).trim() : endPart;
                           
                           if (start.equals(realEnd)) {
                               isImmediate = true;
                               String suffix = hasSuffix ? endPart.substring(endPart.indexOf("(")) : "";
                               displayCreneau = "Départ " + start + " " + suffix;
                           }
                       }
                  }
            %>
                <button id="btn-<%= safeId %>" class="page-btn <%= isImmediate ? "immediate-dept" : "" %> <%= index == 0 ? "active" : "" %>" onclick="showCreneau('<%= safeId %>')">
                    <%= displayCreneau %>
                </button>
            <%    index++;
               } 
            %>
        </div>

        <% 
               index = 0;
               for (Map.Entry<String, List<VehiclePlanningDTO>> entry : planningsParCreneauMap.entrySet()) {
                   String creneau = entry.getKey();
                   String safeId = creneau.replace(":", "").replace(" ", "").replace("-", "_");
                   List<VehiclePlanningDTO> plannings = entry.getValue();
                   List<ReservationDTO> unassigned = unassignedParCreneauMap.get(creneau);
                   
                   boolean isImmediate = false;
                   String displayTitle = "Tranche horaire / <span class=\"malagasy\">Fotoana</span> : " + creneau;
                   
                   if (creneau.contains("-")) {
                       String[] parts = creneau.split("-");
                       if (parts.length >= 2) {
                           String start = parts[0].trim();
                           String endPart = parts[1].trim(); 
                           boolean hasSuffix = endPart.contains("(");
                           String realEnd = hasSuffix ? endPart.substring(0, endPart.indexOf("(")).trim() : endPart;
                           
                           if (start.equals(realEnd)) {
                               isImmediate = true;
                               String suffix = hasSuffix ? endPart.substring(endPart.indexOf("(")) : "";
                               displayTitle = "<span style='color:#d32f2f'>⚡ Départ Immédiat / <span class=\"malagasy\">Miainga avy hatrany</span> : " + start + " " + suffix + "</span>";
                           }
                       }
                   }
        %>
        <div id="section-<%= safeId %>" class="creneau-section <%= index == 0 ? "active" : "" %>">
            <h2 style="color: #2196F3;"><%= displayTitle %></h2>
            <div class="table-section">
                <h2>Réservations assignées / <span class="malagasy">Fandaminana amin'ny fiara</span></h2>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Véhicule / <span class="malagasy">Fiara</span></th>
                            <th>Clients / <span class="malagasy">Mpandeha</span></th>
                            <th>Heure départ / <span class="malagasy">Ora fiaingana</span></th>
                            <th>Heure retour / <span class="malagasy">Ora fiverenana</span></th>
                            <th>Trajet aller / Distance aller</th>
                            <th>Places occupées / <span class="malagasy">Toerana feno</span></th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (plannings != null && !plannings.isEmpty()) {
                               for (VehiclePlanningDTO planning : plannings) { %>
                            <tr>
                                <td class="vehicle-id">
                                    <form action="<%= request.getContextPath() %>/planning/vehicule-detail" method="post" style="display: inline; margin: 0;">
                                        <input type="hidden" name="idVehicule" value="<%= planning.getIdVehicule() %>">
                                        <input type="hidden" name="datePlanning" value="<%= datePlanning != null ? datePlanning : "" %>">
                                        <button type="submit" class="vehicle-id-link" title="Voir les détails du véhicule"><%= planning.getIdVehicule() %></button>
                                    </form>
                                </td>
                                <td><%= planning.getReferenceVehicule() %></td>
                                <td>
                                    <ul class="client-list">
                                        <% for (models.ClientInfo client : planning.getClients()) { %>
                                            <li>
                                                <span class="client-name"><%= client.getNomClient() %></span><br/>
                                                <span class="client-details">
                                                    <%= client.getNbPassager() %> passager(s) - 
                                                    <%= client.getHotel() %><br/>
                                                    Arrivée: <%= client.getHeureArriveeHotel() %>
                                                </span>
                                            </li>
                                        <% } %>
                                    </ul>
                                </td>
                                <td><%= planning.getDateHeureDepart() %></td>
                                <td><%= planning.getDateHeureRetour() %></td>
                                <td>
                                    <div><%= planning.getTrajetResume() != null ? planning.getTrajetResume() : "-" %></div>
                                    <div class="client-details"><%= String.format("%.2f", planning.getDistanceParcourueKm()) %> km</div>
                                </td>
                                <td><%= planning.getPlacesOccupees() %> / <%= planning.getPlacesTotales() %></td>
                            </tr>
                        <%   }
                           } else { %>
                            <tr><td colspan="7" style="text-align:center;">Aucune réservation assignée dans ce créneau / <span class="malagasy">Tsy misy voatokana</span></td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            
            <div class="table-section">
                <h2>Réservations non assignées / <span class="malagasy">Tsy voatokana</span></h2>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Client / <span class="malagasy">Mpandeha</span></th>
                            <th>Nb passagers / <span class="malagasy">Isan'ny mpandeha</span></th>
                            <th>Date arrivée / <span class="malagasy">Daty fahatongavana</span></th>
                            <th>Hôtel / <span class="malagasy">Hotel</span></th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (unassigned != null && !unassigned.isEmpty()) {
                               for (ReservationDTO r : unassigned) { %>
                            <tr>
                                <td><%= r.getId() %></td>
                                <td><%= r.getClient() %></td>
                                <td><%= r.getNbPassager() %></td>
                                <td><%= r.getDateHeureArrivee() %></td>
                                <td><%= r.getHotel() %></td>
                                <td><span class="badge badge-unassigned">Non assignée / <span class="malagasy">Tsy voatokana</span></span></td>
                            </tr>
                        <%   }
                           } else { %>
                            <tr><td colspan="6" style="text-align:center;">Aucune réservation non assignée dans ce créneau / <span class="malagasy">Tsy misy tsy voatokana</span></td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
        <% 
                   index++;
               } 
           } else { 
        %>
            <div class="table-section">
                <p style="text-align:center;">Aucun résultat de planification disponible. / <span class="malagasy">Tsy misy vokatra fandaminana azo ampiasaina.</span></p>
            </div>
        <% } %>

        <div style="margin-top:30px;">
            <div class="francais">
                <strong>Règles de gestion :</strong><br>
                1. Les clients sont inséparables<br>
                2. On assigne les clients au véhicule ayant le nombre de places le plus proche du nombre de passagers<br>
                3. Si on doit réutiliser un véhicule, la priorité est donnée à celui qui a effectué le moins de courses (qui a été le moins utilisé)<br>
                4. Si plusieurs véhicules sont ex-aequo, priorité au diesel<br>
                5. Si égalité totale, on choisit au hasard<br>
                6. Les réservations avec le plus de personnes sont prioritaires<br>
                7. Le lieu le plus proche de l'aéroport est visité en premier<br>
            </div>
            <div class="malagasy">
                <strong>Fitsipika :</strong><br>
                1. Tsy azo sarahana ny mpanjifa<br>
                2. Ny fiara manana toerana akaiky indrindra amin'ny isan'ny mpandeha no omena<br>
                3. Raha mitovy ny toerana, diesel no omena laharana<br>
                4. Raha mitovy tanteraka, random no atao<br>
                5. Ny réservation misy olona maro no omena laharana<br>
                6. Ny toerana akaiky indrindra amin'ny aéroport no aleha voalohany<br>
            </div>
        </div>
    </div>
</body>
</html>
