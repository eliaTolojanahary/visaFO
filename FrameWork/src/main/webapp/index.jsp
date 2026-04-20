<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Visa</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 24px;
        }
        .module-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 16px;
            background: #fafafa;
        }
        .module-card h2 {
            margin: 0 0 8px;
            color: #333;
        }
        .module-card p {
            margin: 0 0 16px;
            color: #555;
            line-height: 1.5;
        }
        .actions {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-block;
            text-decoration: none;
            color: #fff;
            border-radius: 4px;
            padding: 10px 16px;
            font-weight: bold;
        }
        .btn-primary {
            background-color: #4CAF50;
        }
        .btn-primary:hover {
            background-color: #45a049;
        }
        .btn-secondary {
            background-color: #2196F3;
        }
        .btn-secondary:hover {
            background-color: #0b7dda;
        }
        .classes {
            margin-top: 12px;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Module Visa Transformable</h1>
        <p class="subtitle">Sprint 1: gestion de la demande de visa (Nouveau titre)</p>

        <div class="module-card">
            <h2>Demande de visa</h2>
            <p>Creer, valider et enregistrer une demande pour profil Investisseur ou Travailleur.</p>
            <div class="actions">
                <a href="<%= request.getContextPath() %>/visa/form" class="btn btn-primary">Nouvelle demande</a>
                <a href="<%= request.getContextPath() %>/visa/form/error" class="btn btn-secondary">Voir ecran erreur</a>
            </div>
            <div class="classes">
                Classes utilisees: Demande, Demandeur, Passeport, PieceJustificative, VisaDTO
            </div>
        </div>
    </div>
</body>
</html>
