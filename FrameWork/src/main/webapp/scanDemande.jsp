<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.PieceFournie" %>
<%
    String ctx = request.getContextPath();

    @SuppressWarnings("unchecked")
    Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");

    @SuppressWarnings("unchecked")
    List<Map<String, Object>> listePiecesAttendues = (List<Map<String, Object>>) request.getAttribute("listePiecesAttendues");

    boolean demandeComplete = Boolean.TRUE.equals(request.getAttribute("demandeComplete"));
    boolean success = Boolean.TRUE.equals(request.getAttribute("success"));

    String message = request.getAttribute("message") != null ? String.valueOf(request.getAttribute("message")) : null;
    String error = request.getAttribute("error") != null ? String.valueOf(request.getAttribute("error")) : null;

    long demandeId = 0L;
    String refDemande = "-";
    String nom = "-";
    String prenom = "-";
    String statutLibelle = "-";
    boolean verrouille = false;

    if (demande != null) {
        Object idObj = demande.get("demandeId");
        if (idObj instanceof Number) {
            demandeId = ((Number) idObj).longValue();
        } else if (idObj != null) {
            try { demandeId = Long.parseLong(String.valueOf(idObj)); } catch (Exception ignored) {}
        }

        refDemande = demande.get("refDemande") != null ? String.valueOf(demande.get("refDemande")) : "-";
        nom = demande.get("nom") != null ? String.valueOf(demande.get("nom")) : "-";
        prenom = demande.get("prenom") != null ? String.valueOf(demande.get("prenom")) : "-";
        statutLibelle = demande.get("statutLibelle") != null ? String.valueOf(demande.get("statutLibelle")) : "-";
        verrouille = Boolean.TRUE.equals(demande.get("verrouille"));
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Scan Demande</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 24px; }
        .box { border: 1px solid #ddd; border-radius: 8px; padding: 14px; margin-bottom: 14px; }
        .ok { background: #eaf8ea; border-color: #9ed49e; }
        .err { background: #fdecec; border-color: #e9a2a2; }
        .warn { background: #fff5e8; border-color: #f0c48a; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #eee; padding: 10px; text-align: left; vertical-align: top; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 999px; background: #eef2f7; }
        .badge-violet { background: #eadbff; color: #4a2a7a; }
        .muted { color: #666; }
        button[disabled] { opacity: 0.55; cursor: not-allowed; }
        .actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
    </style>
</head>
<body>
    <h1>Gestion des scans</h1>

    <div class="box">
        <p><strong>Référence:</strong> <%= refDemande %></p>
        <p><strong>Demandeur:</strong> <%= nom %> <%= prenom %></p>
        <p>
            <strong>Statut:</strong>
            <span class="badge <%= "Scan termine".equalsIgnoreCase(statutLibelle) ? "badge-violet" : "" %>"><%= statutLibelle %></span>
        </p>
        <p><strong>Demande ID:</strong> <%= demandeId %></p>
    </div>

    <% if (success && message != null) { %>
        <div class="box ok"><strong>Succès:</strong> <%= message %></div>
    <% } %>

    <% if (error != null && !error.trim().isEmpty()) { %>
        <div class="box err"><strong>Erreur:</strong> <%= error %></div>
    <% } %>

    <% if (verrouille) { %>
        <div class="box warn"><strong>Dossier verrouillé.</strong> Plus aucune modification n'est possible.</div>
    <% } %>

    <div class="box">
        <h2>Pièces attendues</h2>
        <% if (listePiecesAttendues == null || listePiecesAttendues.isEmpty()) { %>
            <p class="muted">Aucune pièce attendue (demande complète par défaut).</p>
        <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>Pièce</th>
                        <th>Fichier scanné</th>
                        <th>Upload</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map<String, Object> ligne : listePiecesAttendues) {
                       long pieceRefId = 0L;
                       Object pieceRefObj = ligne.get("pieceRefId");
                       if (pieceRefObj instanceof Number) {
                           pieceRefId = ((Number) pieceRefObj).longValue();
                       } else if (pieceRefObj != null) {
                           try { pieceRefId = Long.parseLong(String.valueOf(pieceRefObj)); } catch (Exception ignored) {}
                       }

                       String pieceLibelle = ligne.get("pieceLibelle") != null ? String.valueOf(ligne.get("pieceLibelle")) : "-";
                       PieceFournie pieceFournie = (PieceFournie) ligne.get("pieceFournie");
                %>
                    <tr>
                        <td><%= pieceLibelle %></td>
                        <td>
                            <% if (pieceFournie != null) { %>
                                <div><strong><%= pieceFournie.getNom_fichier() %></strong></div>
                                <div class="muted">Taille: <%= pieceFournie.getTaille_bytes() %> bytes</div>
                                <div class="muted">Date: <%= pieceFournie.getUploaded_at() %></div>
                                <div>
                                    <a href="<%= ctx %>/demande/<%= demandeId %>/piece/<%= pieceRefId %>/download">Télécharger</a>
                                </div>
                            <% } else { %>
                                <span class="muted">Aucun fichier scanné</span>
                            <% } %>
                        </td>
                        <td>
                            <form method="post" enctype="multipart/form-data" action="<%= ctx %>/demande/<%= demandeId %>/piece/<%= pieceRefId %>/upload">
                                <div class="actions">
                                    <input type="file" name="fichier" accept="image/jpeg,image/png,application/pdf" required <%= verrouille ? "disabled" : "" %> />
                                    <button type="submit" <%= verrouille ? "disabled" : "" %>>Uploader cette pièce</button>
                                </div>
                            </form>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        <% } %>
    </div>

    <div class="box">
        <h2>Finalisation</h2>
        <form method="post" action="<%= ctx %>/demande/<%= demandeId %>/verrouiller" onsubmit="return confirm('Toutes les pièces sont scannées. Verrouiller définitivement le dossier ?');">
            <button type="submit" <%= (!demandeComplete || verrouille) ? "disabled" : "" %>>Scan Terminé</button>
            <% if (!demandeComplete) { %>
                <span class="muted">Le dossier n'est pas encore complet.</span>
            <% } %>
        </form>
    </div>

    <p><a href="<%= ctx %>/dashboard">Retour dashboard</a></p>
</body>
</html>
