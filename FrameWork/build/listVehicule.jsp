<%@ page import="models.Vehicule" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Liste des Véhicules</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            margin: 10px 5px;
            text-decoration: none;
            border-radius: 4px;
            transition: background-color 0.3s;
        }
        .btn-primary {
            background-color: #007bff;
            color: white;
        }
        .btn-primary:hover {
            background-color: #0056b3;
        }
        .btn-warning {
            background-color: #ffc107;
            color: #333;
        }
        .btn-warning:hover {
            background-color: #e0a800;
        }
        .btn-danger {
            background-color: #dc3545;
            color: white;
        }
        .btn-danger:hover {
            background-color: #c82333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #007bff;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .error {
            color: #dc3545;
            padding: 10px;
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .actions {
            white-space: nowrap;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Liste des Véhicules</h1>
        
        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error"><%= error %></div>
        <% } %>
        
        <div>
            <a href="form" class="btn btn-primary">+ Ajouter un véhicule</a>
        </div>
        
        <% List<Vehicule> vehicules = (List<Vehicule>) request.getAttribute("vehicules"); %>
        <% if (vehicules != null && !vehicules.isEmpty()) { %>
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Référence</th>
                        <th>Nombre de places</th>
                        <th>Type de carburant</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Vehicule v : vehicules) { %>
                        <tr>
                            <td><%= v.getId() %></td>
                            <td><%= v.getReference() %></td>
                            <td><%= v.getPlace() %></td>
                            <td><%= v.getTypeCarburant() %></td>
                            <td class="actions">
                                <a href="edit?id=<%= v.getId() %>" class="btn btn-warning">Modifier</a>
                                <a href="delete?id=<%= v.getId() %>" 
                                   class="btn btn-danger" 
                                   onclick="return confirm('Êtes-vous sûr de vouloir supprimer ce véhicule ?');">Supprimer</a>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        <% } else { %>
            <p>Aucun véhicule trouvé.</p>
        <% } %>
    </div>
</body>
</html>
