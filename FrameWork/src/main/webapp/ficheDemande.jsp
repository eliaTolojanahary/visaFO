<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    String ctx = request.getContextPath();

    Long demandeId = null;
    if (request.getAttribute("demandeId") != null) {
        try { demandeId = Long.parseLong(String.valueOf(request.getAttribute("demandeId"))); } catch (Exception ignore) {}
    }
    String demandeIdValue = demandeId != null ? String.valueOf(demandeId) : "";

    Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
    if (demande == null) {
        demande = new java.util.HashMap<>();
    }

    String reference = request.getAttribute("reference") != null ? String.valueOf(request.getAttribute("reference"))
        : String.valueOf(demande.getOrDefault("ref_demande", ""));
    String nomComplet = request.getAttribute("nomComplet") != null ? String.valueOf(request.getAttribute("nomComplet")) : "";
    String statut = demande.get("statutLibelle") != null ? String.valueOf(demande.get("statutLibelle"))
        : String.valueOf(demande.getOrDefault("statut", ""));
    String createdAt = demande.get("createdAt") != null ? String.valueOf(demande.get("createdAt"))
        : String.valueOf(demande.getOrDefault("created_at", ""));

    Boolean attestationDisponible = (Boolean) request.getAttribute("attestationDisponible");
    if (attestationDisponible == null) attestationDisponible = false;

    Boolean locked = (Boolean) request.getAttribute("photoUploaded");
    Boolean signatureUploaded = (Boolean) request.getAttribute("signatureUploaded");

    @SuppressWarnings("unchecked")
    List<Map<String, Object>> pieces = (List<Map<String, Object>>) request.getAttribute("listePiecesAttendues");
    if (pieces == null) {
        pieces = new java.util.ArrayList<>();
    }

    String scanUrl = ctx + "/demande/" + demandeIdValue + "/scan";
    String attestationUrl = ctx + "/demande/" + demandeIdValue + "/attestation";
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiche demande - <%= reference.isEmpty() ? "Dossier" : reference %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <link rel="stylesheet" href="<%= ctx %>/css/scanDemande.css">
    <style>
        body {
            background: linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
        }
        .fiche-shell {
            max-width: 1180px;
            margin: 0 auto;
            padding: 24px 16px 48px;
        }
        .fiche-hero {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 45%, #334155 100%);
            color: #fff;
            border-radius: 24px;
            padding: 28px;
            box-shadow: 0 24px 60px rgba(15, 23, 42, 0.18);
            position: relative;
            overflow: hidden;
        }
        .fiche-hero::after {
            content: '';
            position: absolute;
            inset: auto -90px -120px auto;
            width: 260px;
            height: 260px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.08);
            filter: blur(2px);
        }
        .fiche-title {
            margin: 0 0 12px;
            font-size: 2rem;
            letter-spacing: -0.03em;
        }
        .fiche-meta {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 14px;
            margin-top: 18px;
        }
        .fiche-meta-card {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 16px;
            padding: 14px 16px;
            backdrop-filter: blur(8px);
        }
        .fiche-meta-card span {
            display: block;
            font-size: 0.8rem;
            opacity: 0.8;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }
        .fiche-meta-card strong {
            display: block;
            font-size: 1rem;
            line-height: 1.35;
        }
        .fiche-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin: 20px 0 24px;
        }
        .fiche-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 44px;
            padding: 0 18px;
            border-radius: 14px;
            border: 0;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: transform 0.15s ease, box-shadow 0.15s ease, opacity 0.15s ease;
        }
        .fiche-btn:hover { transform: translateY(-1px); }
        .fiche-btn--primary { background: #e2e8f0; color: #0f172a; box-shadow: 0 10px 24px rgba(15, 23, 42, 0.08); }
        .fiche-btn--accent { background: #f59e0b; color: #111827; box-shadow: 0 10px 24px rgba(245, 158, 11, 0.22); }
        .fiche-btn--muted { background: rgba(15, 23, 42, 0.05); color: #0f172a; }
        .fiche-btn--disabled, .fiche-btn[aria-disabled="true"] {
            opacity: 0.45;
            pointer-events: none;
        }
        .fiche-grid {
            display: grid;
            grid-template-columns: 1.1fr 0.9fr;
            gap: 20px;
        }
        .fiche-card {
            background: rgba(255, 255, 255, 0.92);
            border: 1px solid rgba(148, 163, 184, 0.25);
            border-radius: 22px;
            box-shadow: 0 16px 38px rgba(15, 23, 42, 0.08);
            padding: 22px;
        }
        .fiche-card h2 {
            margin: 0 0 14px;
            font-size: 1.15rem;
        }
        .fiche-lock {
            background: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
            padding: 12px 16px;
            border-radius: 14px;
            margin-bottom: 18px;
            font-weight: 600;
        }
        .piece-list {
            display: grid;
            gap: 12px;
        }
        .piece-row {
            display: flex;
            justify-content: space-between;
            gap: 18px;
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 16px;
            padding: 14px 16px;
            background: #fff;
        }
        .piece-row__title {
            margin: 0 0 4px;
            font-weight: 700;
            color: #0f172a;
        }
        .piece-row__meta {
            margin: 0;
            color: #475569;
            font-size: 0.92rem;
        }
        .piece-badge {
            align-self: flex-start;
            border-radius: 999px;
            padding: 6px 10px;
            font-size: 0.78rem;
            font-weight: 700;
            letter-spacing: 0.04em;
        }
        .piece-badge--ok { background: #dcfce7; color: #166534; }
        .piece-badge--wait { background: #ffedd5; color: #9a3412; }
        .pdf-frame {
            width: 100%;
            min-height: 760px;
            border: 1px solid rgba(148, 163, 184, 0.25);
            border-radius: 18px;
            background: #fff;
        }
        .section-toggle {
            margin-top: 18px;
            display: none;
        }
        .section-toggle.is-visible {
            display: block;
        }
        .helper-text {
            color: #475569;
            margin: 0 0 12px;
            line-height: 1.5;
        }
        @media (max-width: 1024px) {
            .fiche-grid { grid-template-columns: 1fr; }
            .pdf-frame { min-height: 580px; }
        }
    </style>
</head>
<body>
<div class="fiche-shell">
    <div class="fiche-hero">
        <h1 class="fiche-title">Fiche de demande</h1>
        <p class="helper-text" style="color: rgba(255,255,255,0.82); margin-bottom: 0;">
            Vue lecture seule pour le suivi du dossier, les pièces et l'attestation PDF.
        </p>
        <div class="fiche-meta">
            <div class="fiche-meta-card">
                <span>Référence</span>
                <strong><%= reference.isEmpty() ? "N/A" : reference %></strong>
            </div>
            <div class="fiche-meta-card">
                <span>Statut</span>
                <strong><%= statut.isEmpty() ? "N/A" : statut %></strong>
            </div>
            <div class="fiche-meta-card">
                <span>Date création</span>
                <strong><%= createdAt.isEmpty() ? "N/A" : createdAt %></strong>
            </div>
            <div class="fiche-meta-card">
                <span>Demandeur</span>
                <strong><%= nomComplet.isEmpty() ? "N/A" : nomComplet %></strong>
            </div>
        </div>
    </div>

    <% if (Boolean.TRUE.equals(attestationDisponible)) { %>
    <div class="fiche-lock" role="alert">
        Dossier verrouillé après SCAN TERMINE. Les modifications sont désactivées.
    </div>
    <% } %>

    <div class="fiche-actions">
        <a class="fiche-btn fiche-btn--primary <%= Boolean.TRUE.equals(attestationDisponible) ? "fiche-btn--disabled" : "" %>"
           href="<%= Boolean.TRUE.equals(attestationDisponible) ? "#" : scanUrl %>"
           <%= Boolean.TRUE.equals(attestationDisponible) ? "aria-disabled=\"true\"" : "" %>>
            Prendre photo
        </a>
        <button type="button" class="fiche-btn fiche-btn--muted" data-toggle-target="piecesSection">
            Aperçu des pièces justificatives
        </button>
        <button type="button" class="fiche-btn fiche-btn--accent <%= Boolean.TRUE.equals(attestationDisponible) ? "" : "fiche-btn--disabled" %>"
                data-toggle-target="pdfSection"
                <%= Boolean.TRUE.equals(attestationDisponible) ? "" : "disabled" %>>
            PDF d’attestation "Dossier pris en compte"
        </button>
    </div>

    <div class="fiche-grid">
        <div class="fiche-card">
            <h2>Aperçu des pièces</h2>
            <p class="helper-text">Les pièces attendues sont listées avec leur statut d'upload. Aucun téléchargement direct n'est exposé ici.</p>
            <div class="piece-list">
                <% for (Map<String, Object> piece : pieces) {
                    String libelle = piece.get("pieceLibelle") != null ? String.valueOf(piece.get("pieceLibelle")) : "Pièce";
                    String statutPiece = piece.get("scanStatut") != null ? String.valueOf(piece.get("scanStatut")) : "EN_ATTENTE";
                    String fileName = piece.get("fileName") != null ? String.valueOf(piece.get("fileName")) : "";
                    String uploadedAt = piece.get("uploadedAt") != null ? String.valueOf(piece.get("uploadedAt")) : "";
                    boolean uploaded = "SCANNÉ".equalsIgnoreCase(statutPiece) || "SCANNED".equalsIgnoreCase(statutPiece);
                %>
                <div class="piece-row">
                    <div>
                        <p class="piece-row__title"><%= libelle %></p>
                        <p class="piece-row__meta">
                            <%= uploaded ? "Fichier: " + fileName : "Aucun fichier" %>
                            <% if (!uploadedAt.isEmpty()) { %>
                            <br><%= uploadedAt %>
                            <% } %>
                        </p>
                    </div>
                    <span class="piece-badge <%= uploaded ? "piece-badge--ok" : "piece-badge--wait" %>">
                        <%= uploaded ? "Uploadé" : "En attente" %>
                    </span>
                </div>
                <% } %>
            </div>
        </div>

        <div class="fiche-card">
            <h2>Résumé d'attestation</h2>
            <p class="helper-text">La zone PDF ne s'affiche qu'après SCAN TERMINE.</p>
            <div class="piece-row" style="margin-bottom: 12px;">
                <div>
                    <p class="piece-row__title">Photo identité</p>
                    <p class="piece-row__meta"><%= Boolean.TRUE.equals(attestationDisponible) ? "Accessible dans l'attestation" : "Lecture seule en attente" %></p>
                </div>
                <span class="piece-badge <%= Boolean.TRUE.equals(attestationDisponible) ? "piece-badge--ok" : "piece-badge--wait" %>">
                    <%= Boolean.TRUE.equals(attestationDisponible) ? "Disponible" : "Bloquée" %>
                </span>
            </div>
            <div class="piece-row">
                <div>
                    <p class="piece-row__title">Signature</p>
                    <p class="piece-row__meta"><%= Boolean.TRUE.equals(attestationDisponible) ? "Incluse dans le flux final" : "Lecture seule en attente" %></p>
                </div>
                <span class="piece-badge <%= Boolean.TRUE.equals(attestationDisponible) ? "piece-badge--ok" : "piece-badge--wait" %>">
                    <%= Boolean.TRUE.equals(attestationDisponible) ? "Disponible" : "Bloquée" %>
                </span>
            </div>
        </div>
    </div>

    <div class="fiche-card section-toggle" id="piecesSection">
        <h2>Détails des pièces</h2>
        <p class="helper-text">Section détaillée des statuts uploadés, sans téléchargement direct.</p>
        <div class="piece-list">
            <% for (Map<String, Object> piece : pieces) {
                String libelle = piece.get("pieceLibelle") != null ? String.valueOf(piece.get("pieceLibelle")) : "Pièce";
                String statutPiece = piece.get("scanStatut") != null ? String.valueOf(piece.get("scanStatut")) : "EN_ATTENTE";
                String fileName = piece.get("fileName") != null ? String.valueOf(piece.get("fileName")) : "";
                String uploadedAt = piece.get("uploadedAt") != null ? String.valueOf(piece.get("uploadedAt")) : "";
                boolean uploaded = "SCANNÉ".equalsIgnoreCase(statutPiece) || "SCANNED".equalsIgnoreCase(statutPiece);
            %>
            <div class="piece-row">
                <div>
                    <p class="piece-row__title"><%= libelle %></p>
                    <p class="piece-row__meta">Statut: <%= uploaded ? "Uploadé" : "En attente" %><% if (!fileName.isEmpty()) { %> | Fichier: <%= fileName %><% } %><% if (!uploadedAt.isEmpty()) { %><br><%= uploadedAt %><% } %></p>
                </div>
                <span class="piece-badge <%= uploaded ? "piece-badge--ok" : "piece-badge--wait" %>">
                    <%= uploaded ? "OK" : "À faire" %>
                </span>
            </div>
            <% } %>
        </div>
    </div>

    <div class="fiche-card section-toggle" id="pdfSection">
        <h2>Attestation PDF</h2>
        <p class="helper-text">Aucun bouton de téléchargement direct n'est exposé. Le document est intégré en lecture seule.</p>
        <% if (Boolean.TRUE.equals(attestationDisponible)) { %>
        <iframe class="pdf-frame" src="<%= attestationUrl %>" title="PDF d'attestation"></iframe>
        <% } else { %>
        <div class="piece-row">
            <div>
                <p class="piece-row__title">Attestation indisponible</p>
                <p class="piece-row__meta">Le PDF apparaîtra lorsque le dossier passera en SCAN TERMINE.</p>
            </div>
            <span class="piece-badge piece-badge--wait">Bloquée</span>
        </div>
        <% } %>
    </div>
</div>

<script>
(function () {
    function toggleSection(targetId) {
        var section = document.getElementById(targetId);
        if (!section) return;
        section.classList.toggle('is-visible');
    }

    document.querySelectorAll('[data-toggle-target]').forEach(function (button) {
        button.addEventListener('click', function () {
            var targetId = button.getAttribute('data-toggle-target');
            if (!targetId) return;
            toggleSection(targetId);
        });
    });
})();
</script>
</body>
</html>
