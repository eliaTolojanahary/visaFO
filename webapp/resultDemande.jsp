<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat - Demande de Visa</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .success-message {
            background: #e6f4ea;
            color: #1d6f37;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            border-left: 4px solid #1d6f37;
        }
        .success-message h2 {
            margin: 0;
            color: #1d6f37;
        }
        .table-container {
            overflow-x: auto;
            margin-bottom: 25px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        }
        thead {
            background: #f0f4f8;
        }
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #1a4a7a;
            border-bottom: 2px solid #e4e9f2;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e4e9f2;
        }
        tr:hover {
            background: #f8fafd;
        }
        .action-links {
            display: flex;
            gap: 10px;
        }
        .btn-secondary {
            display: inline-block;
            padding: 10px 16px;
            background: #e8eef7;
            color: #1a4a7a;
            text-decoration: none;
            border-radius: 6px;
            font-size: 0.9rem;
            transition: background 0.2s ease;
        }
        .btn-secondary:hover {
            background: #d4dfe9;
        }
        .btn-primary {
            display: inline-block;
            padding: 10px 16px;
            background: #1a4a7a;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-size: 0.9rem;
            transition: background 0.2s ease;
        }
        .btn-primary:hover {
            background: #163f6d;
        }
    </style>
</head>
<body>
<div class="container">
    <header>
        <h1>Résultat - Demande de Visa</h1>
    </header>

    <div class="success-message">
        <h2>✓ Demande créée avec succès</h2>
        <p>Votre demande de visa a été enregistrée dans le système.</p>
    </div>

    <div class="form-section">
        <h2>Détails de votre demande</h2>
        <c:if test="${not empty demande}">
            <div class="table-container">
                <table>
                    <tr>
                        <th>Champ</th>
                        <th>Valeur</th>
                    </tr>
                    <tr>
                        <td><strong>ID Demande</strong></td>
                        <td>${demande.id}</td>
                    </tr>
                    <tr>
                        <td><strong>Type de Demande</strong></td>
                        <td>${demande.typeDemande}</td>
                    </tr>
                    <tr>
                        <td><strong>Profil</strong></td>
                        <td>${demande.profil}</td>
                    </tr>
                    <tr>
                        <td><strong>Statut</strong></td>
                        <td><strong style="color: #27ae60;">${demande.statut}</strong></td>
                    </tr>
                    <tr>
                        <td><strong>Date de création</strong></td>
                        <td>${demande.dateCreation}</td>
                    </tr>
                </table>
            </div>
        </c:if>
    </div>

    <div class="form-section">
        <h2>Liste de vos demandes</h2>
        <c:if test="${not empty demandes}">
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>ID Demande</th>
                            <th>Nom</th>
                            <th>Prénom</th>
                            <th>Type</th>
                            <th>Profil</th>
                            <th>Statut</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="dem" items="${demandes}">
                            <tr>
                                <td>${dem.id}</td>
                                <td>${dem.nom}</td>
                                <td>${dem.prenom}</td>
                                <td>${dem.typeDemande}</td>
                                <td>${dem.profil}</td>
                                <td><strong style="color: #27ae60;">${dem.statut}</strong></td>
                                <td>
                                    <div class="action-links">
                                        <a href="${pageContext.request.contextPath}/visa/edit?id=${dem.id}" class="btn-secondary">Modifier</a>
                                        <a href="${pageContext.request.contextPath}/visa/delete?id=${dem.id}" class="btn-secondary" onclick="return confirm('Êtes-vous sûr?')">Supprimer</a>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:if>
        <c:if test="${empty demandes}">
            <p>Aucune demande trouvée.</p>
        </c:if>
    </div>

    <div style="margin-top: 25px;">
        <a href="${pageContext.request.contextPath}/visa/form" class="btn-primary">Créer une nouvelle demande</a>
        <a href="${pageContext.request.contextPath}/visa/list" class="btn-secondary" style="margin-left: 10px;">Voir toutes les demandes</a>
    </div>
</div>
</body>
</html>