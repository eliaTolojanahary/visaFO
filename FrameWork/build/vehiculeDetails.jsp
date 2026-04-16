<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Détail Planning Véhicule</title>
    <style>
        /* ---- Reset & base ---- */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            font-size: 14px;
            background: #f0f4f8;
            color: #1e293b;
            padding: 32px 16px;
            min-height: 100vh;
        }

        /* ---- Conteneur principal ---- */
        .container {
            max-width: 1100px;
            margin: 0 auto;
        }

        /* ---- Titre page ---- */
        .page-title {
            font-size: 22px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 24px;
            padding-bottom: 12px;
            border-bottom: 2px solid #4f46e5;
            display: inline-block;
        }

        /* ---- Cartes info véhicule ---- */
        .cards {
            display: flex;
            gap: 16px;
            margin-bottom: 28px;
            flex-wrap: wrap;
        }

        .card {
            flex: 1;
            min-width: 200px;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 18px 22px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.07);
        }

        .card-label {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: #94a3b8;
            margin-bottom: 6px;
        }

        .card-value {
            font-size: 24px;
            font-weight: 700;
            color: #4f46e5;
        }

        .card-value.green { color: #16a34a; }

        .card-value span.unit {
            font-size: 13px;
            font-weight: 400;
            color: #94a3b8;
            margin-left: 4px;
        }

        /* ---- Bloc tableau ---- */
        .table-block {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 1px 4px rgba(0,0,0,0.07);
        }

        .table-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 20px;
            border-bottom: 1px solid #e2e8f0;
            background: #f8fafc;
        }

        .table-header h2 {
            font-size: 15px;
            font-weight: 600;
            color: #1e293b;
        }

        .badge {
            font-size: 11px;
            color: #64748b;
            background: #e2e8f0;
            border-radius: 999px;
            padding: 3px 10px;
        }

        /* ---- Table ---- */
        .table-wrap { overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        thead tr {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
        }

        thead th {
            padding: 10px 16px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.07em;
            color: #94a3b8;
            text-align: left;
            white-space: nowrap;
        }

        thead th.right { text-align: right; }
        thead th.center { text-align: center; }

        tbody tr {
            border-bottom: 1px solid #f1f5f9;
            transition: background 0.15s;
        }

        tbody tr:last-child { border-bottom: none; }
        tbody tr:hover { background: #f0f4ff; }

        tbody td {
            padding: 12px 16px;
            color: #334155;
            vertical-align: middle;
        }

        td.num    { color: #94a3b8; font-size: 12px; font-family: monospace; }
        td.bold   { font-weight: 600; color: #1e293b; }
        td.right  { text-align: right; }
        td.center { text-align: center; }

        .date-badge {
            display: inline-block;
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 2px 8px;
            font-family: monospace;
            font-size: 12px;
            color: #475569;
        }

        .pax-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            background: #ede9fe;
            color: #4f46e5;
            font-weight: 700;
            font-size: 13px;
        }

        .dist-lieu  { color: #d97706; font-weight: 600; }
        .dist-total { color: #16a34a; font-weight: 600; }

        /* ---- État vide ---- */
        .empty {
            text-align: center;
            padding: 60px 20px;
            color: #94a3b8;
            font-size: 14px;
        }

        /* ---- Pied de page ---- */
        .footer {
            text-align: center;
            margin-top: 28px;
            font-size: 12px;
            color: #cbd5e1;
        }
    </style>
</head>
<body>
<div class="container">

    <h1 class="page-title">Détail du Planning</h1>

    <%-- ===== CARTES VÉHICULE ===== --%>
    <div class="cards">
        <div class="card">
            <div class="card-label">ID du véhicule</div>
            <div class="card-value">${not empty planning.vehiculeId ? planning.vehiculeId : '—'}</div>
        </div>
        <div class="card">
            <div class="card-label">Distance totale parcourue</div>
            <div class="card-value green">
                ${not empty planning.distanceTotale ? planning.distanceTotale : '—'}
                <span class="unit">km</span>
            </div>
        </div>
    </div>
    <%
        List plannings = (List) request.getAttribute("plannings");
        int nbTrajets = (plannings != null) ? plannings.size() : 0;
    %>

    <%-- ===== TABLEAU DES TRAJETS ===== --%>
    <div class="table-block">
        <div class="table-header">
            <h2>Trajets effectués</h2>
            <span class="badge"><%= nbTrajets %> trajet<%= nbTrajets > 1 ? "s" : "" %></span>
        </div>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Nom du client</th>
                        <th>Date &amp; heure d'arrivée</th>
                        <th class="center">Passagers</th>
                        <th>Lieu d'arrivée</th>
                        <th class="right">Dist. entre lieux (km)</th>
                        <th class="right">Dist. véhicule (km)</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (plannings != null && !plannings.isEmpty()) {
                        for (int i = 0; i < plannings.size(); i++) {
                            pageContext.setAttribute("p", plannings.get(i));
                    %>
                                <tr>
                                    <td class="num"><%= i + 1 %></td>
                                    <td class="bold">${p.nomClient}</td>
                                    <td><span class="date-badge">${p.dateHeureArrivee}</span></td>
                                    <td class="center"><span class="pax-badge">${p.nombrePassager}</span></td>
                                    <td>${p.lieuArrivee}</td>
                                    <td class="right dist-lieu">${p.distanceEntreChaqueLieu}</td>
                                    <td class="right dist-total">${p.distanceParcourue}</td>
                                </tr>
                    <% } } else { %>
                                <tr>
                                    <td colspan="7" class="empty">Aucun trajet disponible pour ce véhicule.</td>
                                </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <p class="footer">Front Office &bull; Mr Vahatra</p>
</div>
</body>
</html>