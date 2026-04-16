<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Mr Vahatra</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
            padding: 30px;
        }
        
        .header h1 {
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            padding: 20px;
        }
        
        .card {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            cursor: pointer;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }
        
        .card-icon {
            font-size: 3em;
            margin-bottom: 15px;
            text-align: center;
        }
        
        .card-title {
            font-size: 1.5em;
            color: #333;
            margin-bottom: 10px;
            text-align: center;
            font-weight: bold;
        }
        
        .card-description {
            color: #666;
            text-align: center;
            margin-bottom: 20px;
            line-height: 1.5;
        }
        
        .card-actions {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        .btn {
            display: block;
            padding: 12px 20px;
            text-decoration: none;
            border-radius: 8px;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s ease;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-primary:hover {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
        }
        
        .btn-secondary {
            background: #f0f0f0;
            color: #333;
        }
        
        .btn-secondary:hover {
            background: #e0e0e0;
        }
        
        .card.reservation {
            border-top: 5px solid #667eea;
        }
        
        .card.vehicule {
            border-top: 5px solid #f093fb;
        }
        
        .card.planning {
            border-top: 5px solid #4facfe;
        }
        
        .footer {
            text-align: center;
            color: white;
            margin-top: 50px;
            padding: 20px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚗 Mr Vahatra</h1>
            <p>Système de gestion de réservation et de planning</p>
        </div>
        
        <div class="dashboard-grid">
            <!-- Card Réservations -->
            <div class="card reservation">
                <div class="card-icon">📅</div>
                <h2 class="card-title">Réservations</h2>
                <p class="card-description">
                    Gérer les réservations des clients, consulter les réservations existantes et créer de nouvelles réservations.
                </p>
                <div class="card-actions">
                    <a href="reservation/form" class="btn btn-primary">Nouvelle réservation</a>
                    <a href="reservation/list" class="btn btn-secondary">Liste des réservations</a>
                </div>
            </div>
            
            <!-- Card Véhicules -->
            <div class="card vehicule">
                <div class="card-icon">🚙</div>
                <h2 class="card-title">Véhicules</h2>
                <p class="card-description">
                    Gérer le parc automobile, ajouter de nouveaux véhicules, modifier ou supprimer les véhicules existants.
                </p>
                <div class="card-actions">
                    <a href="vehicule/form" class="btn btn-primary">Ajouter un véhicule</a>
                    <a href="vehicule/list" class="btn btn-secondary">Liste des véhicules</a>
                </div>
            </div>
            
            <!-- Card Planning -->
            <div class="card planning">
                <div class="card-icon">🗺️</div>
                <h2 class="card-title">Planning</h2>
                <p class="card-description">
                    Configurer les paramètres du planning, visualiser les réservations par date et gérer les itinéraires.
                </p>
                <div class="card-actions">
                    <a href="planning/config/form" class="btn btn-primary">Configuration système</a>
                    <a href="planning/selection-date" class="btn btn-secondary">Planning par date</a>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>© 2026 Mr Vahatra - Tous droits réservés</p>
        </div>
    </div>
</body>
</html>
