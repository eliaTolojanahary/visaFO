<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.PieceFournie" %>
<%
    String ctx = request.getContextPath();

    @SuppressWarnings("unchecked")
    Map<String, Object> suivi = (Map<String, Object>) request.getAttribute("suivi");

    @SuppressWarnings("unchecked")
    List<PieceFournie> piecesScannees = (List<PieceFournie>) request.getAttribute("piecesScannees");

    boolean success = Boolean.TRUE.equals(request.getAttribute("success"));
    String message = request.getAttribute("message") != null ? String.valueOf(request.getAttribute("message")) : null;
    String error = request.getAttribute("error") != null ? String.valueOf(request.getAttribute("error")) : null;

    long demandeId = 0L;
    String refDemande = "-";
    String nom = "-";
    String prenom = "-";
    String statutLibelle = "-";
    boolean verrouille = false;

    if (suivi != null) {
        Object idObj = suivi.get("demandeId");
        if (idObj instanceof Number) {
            demandeId = ((Number) idObj).longValue();
        } else if (idObj != null) {
            try { demandeId = Long.parseLong(String.valueOf(idObj)); } catch (Exception ignored) {}
        }

        refDemande = suivi.get("refDemande") != null ? String.valueOf(suivi.get("refDemande")) : "-";
        nom = suivi.get("nom") != null ? String.valueOf(suivi.get("nom")) : "-";
        prenom = suivi.get("prenom") != null ? String.valueOf(suivi.get("prenom")) : "-";
        statutLibelle = suivi.get("statutLibelle") != null ? String.valueOf(suivi.get("statutLibelle")) : "-";
        verrouille = Boolean.TRUE.equals(suivi.get("verrouille"));
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Suivi du dossier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 24px; }
        .box { border: 1px solid #ddd; border-radius: 8px; padding: 14px; margin-bottom: 14px; }
        .ok { background: #eaf8ea; border-color: #9ed49e; }
        .err { background: #fdecec; border-color: #e9a2a2; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 999px; background: #eef2f7; }
        .badge-violet { background: #eadbff; color: #4a2a7a; }
        .muted { color: #666; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #eee; padding: 10px; text-align: left; }
    </style>
</head>
<body>
    <h1>Suivi du dossier</h1>

    <% if (success && message != null) { %>
        <div class="box ok"><strong>Succès:</strong> <%= message %></div>
    <% } %>

    <% if (error != null && !error.trim().isEmpty()) { %>
        <div class="box err"><strong>Erreur:</strong> <%= error %></div>
    <% } %>

    <div class="box">
        <p><strong>Référence:</strong> <%= refDemande %></p>
        <p><strong>Demandeur:</strong> <%= nom %> <%= prenom %></p>
        <p>
            <strong>Statut:</strong>
            <span class="badge <%= "Scan termine".equalsIgnoreCase(statutLibelle) ? "badge-violet" : "" %>"><%= statutLibelle %></span>
        </p>
        <p><strong>Verrouillé:</strong> <%= verrouille ? "Oui" : "Non" %></p>
    </div>

    <div class="box">
        <h2>Documents scannés</h2>
        <% if (piecesScannees == null || piecesScannees.isEmpty()) { %>
            <p class="muted">Aucun document scanné pour l'instant.</p>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Pièce</th>
                        <th>Fichier</th>
                        <th>Taille</th>
                        <th>Date</th>
                        <th>Téléchargement</th>
                    </tr>
                </thead>
                <tbody>
                <% for (PieceFournie pf : piecesScannees) {
                       long pieceRefId = pf.getPiece_ref() != null ? pf.getPiece_ref().getId() : 0L;
                       String pieceLibelle = (pf.getPiece_ref() != null && pf.getPiece_ref().getLibelle() != null)
                           ? pf.getPiece_ref().getLibelle() : "-";
                %>
                    <tr>
                        <td><%= pieceLibelle %></td>
                        <td><%= pf.getNom_fichier() != null ? pf.getNom_fichier() : "-" %></td>
                        <td><%= pf.getTaille_bytes() %> bytes</td>
                        <td><%= pf.getUploaded_at() %></td>
                        <td>
                            <a href="<%= ctx %>/demande/<%= demandeId %>/piece/<%= pieceRefId %>/download">Télécharger</a>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } %>
    </div>

    <% if (demandeId > 0L) { %>
        <p><a href="<%= ctx %>/demande/<%= demandeId %>/scan">Ouvrir la page scan</a></p>
    <% } %>
    <p><a href="<%= ctx %>/dashboard">Retour dashboard</a></p>
</body>
</html>
