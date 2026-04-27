<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.Demande" %>
<% String ctx = request.getContextPath(); %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat - Demande de Visa</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <style>
        .success-message {
            background: #e6f4ea;
            color: #1d6f37;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            border-left: 4px solid #1d6f37;
        }
        .error-message {
            background: #fce8e8;
            color: #c0392b;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            border-left: 4px solid #c0392b;
        }
        .success-message h2, .error-message h2 { margin: 0; }
        .table-container { overflow-x: auto; margin-bottom: 25px; }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        thead { background: #f0f4f8; }
        th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #1a4a7a;
            border-bottom: 2px solid #e4e9f2;
        }
        td { padding: 12px 15px; border-bottom: 1px solid #e4e9f2; }
        tr:hover { background: #f8fafd; }
        .action-links { display: flex; gap: 10px; }
        .btn-secondary {
            display: inline-block; padding: 10px 16px;
            background: #e8eef7; color: #1a4a7a;
            text-decoration: none; border-radius: 6px;
            font-size: 0.9rem; transition: background 0.2s ease;
            border: none; cursor: pointer;
        }
        .btn-secondary:hover { background: #d4dfe9; }
        .btn-primary {
            display: inline-block; padding: 10px 16px;
            background: #1a4a7a; color: white;
            text-decoration: none; border-radius: 6px;
            font-size: 0.9rem; transition: background 0.2s ease;
            border: none; cursor: pointer;
        }
        .btn-primary:hover { background: #163f6d; }
        .btn-warning {
            display: inline-block; padding: 10px 16px;
            background: #e67e22; color: white;
            text-decoration: none; border-radius: 6px;
            font-size: 0.9rem; transition: background 0.2s ease;
            border: none; cursor: pointer;
        }
        .btn-warning:hover { background: #d35400; }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 18px;
            margin-bottom: 25px;
        }
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            border: 1px solid #e4e9f2;
        }
        .card h2 { margin-top: 0; }
        .card-actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }
        .meta-list { margin: 0; padding: 0; list-style: none; }
        .meta-list li { margin-bottom: 8px; }
        .badge {
            display: inline-flex;
            align-items: center;
            border-radius: 999px;
            padding: 4px 10px;
            font-size: 0.82rem;
            font-weight: 700;
        }
        .badge-orange { background: #fff1da; color: #915c00; }
        .badge-blue { background: #e4efff; color: #1f4f9a; }
        .badge-green { background: #e2f6ea; color: #1f7a42; }
        .badge-red { background: #fce8e8; color: #b2271a; }
        .badge-gray { background: #edf1f6; color: #506075; }
    </style>
</head>
<body>
<div class="container">
    <header>
        <h1>Dashboard - Demande de Visa</h1>
    </header>

    <%
        Boolean success = (Boolean) request.getAttribute("success");
        String message  = (String)  request.getAttribute("message");
        String error    = (String)  request.getAttribute("error");
        String action   = (String)  request.getAttribute("action"); // "update" ou null
        Demande demande = (Demande) request.getAttribute("demande");
    %>

    <%-- ===== BLOC SUCCÈS / ERREUR ===== --%>
    <% if (success != null && success) { %>
        <div class="success-message">
            <h2>✓ <%= "update".equals(action) ? "Demande mise à jour avec succès" : "Demande créée avec succès" %></h2>
            <p><%= message != null ? message : "Votre demande de visa a été enregistrée dans le système." %></p>
        </div>
    <% } else if (success != null && !success) { %>
        <div class="error-message">
            <h2>✗ <%= "update".equals(action) ? "Erreur lors de la mise à jour" : "Erreur lors de la création" %></h2>
            <p><%= error != null ? error : "Une erreur est survenue lors de l'enregistrement de votre demande." %></p>
        </div>
    <% } %>

    <%
        @SuppressWarnings("unchecked")
        Map<String, Object> latestDemande = (Map<String, Object>) request.getAttribute("latestDemande");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> dashboardDemandes = (List<Map<String, Object>>) request.getAttribute("dashboardDemandes");
        boolean dashboardMode = Boolean.TRUE.equals(request.getAttribute("dashboardMode"));
        String highlightDemandeId = request.getAttribute("highlightDemandeId") != null
            ? String.valueOf(request.getAttribute("highlightDemandeId"))
            : "";

        String latestTypeDemande = latestDemande != null && latestDemande.get("typeDemandeLibelle") != null
            ? String.valueOf(latestDemande.get("typeDemandeLibelle"))
            : "";
        String latestStatut = latestDemande != null && latestDemande.get("statutLibelle") != null
            ? String.valueOf(latestDemande.get("statutLibelle"))
            : "";

        String statusClass = "badge-gray";
        if (latestStatut.equalsIgnoreCase("En cours de traitement")) statusClass = "badge-blue";
        else if (latestStatut.equalsIgnoreCase("En attente")) statusClass = "badge-orange";
        else if (latestStatut.equalsIgnoreCase("Valide")) statusClass = "badge-green";
        else if (latestStatut.equalsIgnoreCase("Refuse")) statusClass = "badge-red";

        boolean duplicata = latestTypeDemande.equalsIgnoreCase("Duplicata");
    %>

    <div class="dashboard-grid">
        <div class="card">
            <h2>Créer une demande</h2>
            <p>Commencer une nouvelle demande de visa ou ouvrir le formulaire pour une modification.</p>
            <div class="card-actions">
                <a href="<%= ctx %>/form" class="btn-primary">Créer une demande</a>
            </div>
        </div>

        <div class='card' >
            <h2>Faire un scan sur un document</h2>
            <p>Commencer une nouvelle demande de visa ou ouvrir le formulaire pour une modification.</p>
            <div class="card-actions">
                <a href='<%= ctx %>/form/scan' class="btn-primary">Faire un scan</a>
            </div>
        </div>

        <div class="card">
            <h2>Dernière demande</h2>
            <% if (latestDemande != null) { %>
                <ul class="meta-list">
                    <li><strong>Nom:</strong> <%= latestDemande.get("nom") != null ? latestDemande.get("nom") : "-" %></li>
                    <li><strong>Prénom:</strong> <%= latestDemande.get("prenom") != null ? latestDemande.get("prenom") : "-" %></li>
                    <li><strong>Numéro passeport:</strong> <%= latestDemande.get("numeroPasseport") != null ? latestDemande.get("numeroPasseport") : "-" %></li>
                    <li><strong>Type de demande:</strong> <%= latestDemande.get("typeDemandeLibelle") != null ? latestDemande.get("typeDemandeLibelle") : "-" %>
                        <% if (duplicata) { %>
                            <span class="badge badge-orange" style="margin-left:8px;">Duplicata - antecedent non retrouve</span>
                        <% } %>
                    </li>
                    <li><strong>Type de titre:</strong> <%= latestDemande.get("typeTitreLibelle") != null ? latestDemande.get("typeTitreLibelle") : "-" %></li>
                    <li><strong>Statut:</strong>
                        <span class="badge <%= statusClass %>"><%= latestDemande.get("statutLibelle") != null ? latestDemande.get("statutLibelle") : "-" %></span>
                    </li>
                    <% if (duplicata) { %>
                        <li><strong>Visa approuve:</strong> <span class="badge badge-green">Confirme par agent</span></li>
                    <% } %>
                    <li><strong>Date de création:</strong> <%= latestDemande.get("createdAt") != null ? latestDemande.get("createdAt") : "-" %></li>
                </ul>
                <div class="card-actions">
                    <form action="<%= ctx %>/form/edit" method="post" style="display:inline;">
                        <input type="hidden" name="demande_id" value="<%= latestDemande.get("demande_id") != null ? latestDemande.get("demande_id") : "" %>">
                        <button type="submit" class="btn-secondary">Modifier</button>
                    </form>
                </div>
            <% } else { %>
                <p>Aucune demande trouvée pour le moment.</p>
            <% } %>
        </div>
    </div>

    <%-- ===== DÉTAILS DE LA DEMANDE CRÉÉE/MODIFIÉE ===== --%>
    <% if (!dashboardMode && demande != null) { %>
        <%
            String nomDemande = (demande.getPasseport() != null && demande.getPasseport().getDemandeur() != null
                && demande.getPasseport().getDemandeur().getNom() != null)
                ? demande.getPasseport().getDemandeur().getNom() : "-";
            String prenomDemande = (demande.getPasseport() != null && demande.getPasseport().getDemandeur() != null
                && demande.getPasseport().getDemandeur().getPrenom() != null)
                ? demande.getPasseport().getDemandeur().getPrenom() : "-";
            String typeDemandeLibelle = (demande.getType_demande() != null && demande.getType_demande().getLibelle() != null)
                ? demande.getType_demande().getLibelle() : "-";
            String typeTitreLibelle = (demande.getType_titre() != null && demande.getType_titre().getLibelle() != null)
                ? demande.getType_titre().getLibelle() : "-";
            String statutDemandeLibelle = (demande.getStatut() != null && demande.getStatut().getLibelle() != null)
                ? demande.getStatut().getLibelle() : "-";
        %>
        <div class="form-section">
            <h2>Détails de votre demande</h2>
            <div class="table-container">
                <table>
                    <thead>
                    <tr>
                        <th>Champ</th>
                        <th>Valeur</th>
                    </tr>
                    </thead>
                    <tbody>

                    <tr>
                        <td><strong>Type de Demande</strong></td>
                        <td><%= typeDemandeLibelle %></td>
                    </tr>
                    <tr>
                        <td><strong>Type de titre</strong></td>
                        <td><%= typeTitreLibelle %></td>
                    </tr>
                    <tr>
                        <td><strong>Statut</strong></td>
                        <td><strong style="color: #27ae60;"><%= statutDemandeLibelle %></strong></td>
                    </tr>
                    <tr>
                        <td><strong>Date de création</strong></td>
                        <td><%= demande.getCreated_at() != null ? demande.getCreated_at() : "-" %></td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>
    <% } %>

    <%-- ===== LISTE DES DEMANDES (si disponible) ===== --%>
    <% if (dashboardDemandes != null && !dashboardDemandes.isEmpty()) { %>
        <div class="form-section">
            <h2>Liste de vos demandes</h2>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nom</th>
                            <th>Prénom</th>
                            <th>Type</th>
                            <th>Profil</th>
                            <th>Statut</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String, Object> d : dashboardDemandes) { %>
                            <%
                            String demandeId = d.get("demande_id") != null ? String.valueOf(d.get("demande_id")) : "";
                            boolean isHighlighted = !highlightDemandeId.isEmpty() && highlightDemandeId.equals(demandeId);
                            String nom = d.get("nom") != null ? String.valueOf(d.get("nom")) : "-";
                            String prenom = d.get("prenom") != null ? String.valueOf(d.get("prenom")) : "-";
                            String typeDemande = d.get("typeDemandeLibelle") != null ? String.valueOf(d.get("typeDemandeLibelle")) : "-";
                            String typeTitre = d.get("typeTitreLibelle") != null ? String.valueOf(d.get("typeTitreLibelle")) : "-";
                            String statut = d.get("statutLibelle") != null ? String.valueOf(d.get("statutLibelle")) : "-";
                            %>
                            <tr class="<%= isHighlighted ? "demand-row-highlight" : "" %>">
                                <td>
                                    <%= demandeId %>
                                    <% if (isHighlighted) { %>
                                        <span class="badge badge-orange" style="margin-left:8px;">Derniere soumission</span>
                                    <% } %>
                                </td>
                            <td><%= nom %></td>
                            <td><%= prenom %></td>
                            <td><%= typeDemande %></td>
                            <td><%= typeTitre %></td>
                            <td><strong style="color: #27ae60;"><%= statut %></strong></td>
                                <td>
                                    <div class="action-links">
                                        <form action="<%= ctx %>/form/edit" method="post" style="display:inline;">
                                            <input type="hidden" name="demande_id" value="<%= demandeId %>">
                                            <button type="submit" class="btn-secondary">Modifier</button>
                                        </form>
                                        <%-- Supprimer : à adapter si vous ajoutez un mapping delete --%>
                                                                                <span class="btn-warning">Supprimer indisponible</span>
                                    </div>
                                </td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    <% } %>

    <div style="margin-top: 25px;">
        <a href="<%= ctx %>/form" class="btn-primary">Créer une nouvelle demande</a>
        <span class="btn-secondary" style="margin-left: 10px;">Liste complète des demandes indisponible</span>
    </div>
</div>
</body>
</html>