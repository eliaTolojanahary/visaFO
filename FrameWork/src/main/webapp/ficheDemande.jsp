<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="models.PieceFournie" %>
<% 
    // Initialisation et traitement des variables classiques JSP
    String ctx = request.getContextPath();
    Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
    List<PieceFournie> piecesFournies = (List<PieceFournie>) request.getAttribute("piecesFournies");
    
    long photoIdentiteRefId = request.getAttribute("photoIdentiteRefId") != null ? Long.parseLong(String.valueOf(request.getAttribute("photoIdentiteRefId"))) : -1L;
    long signatureNumeriqueRefId = request.getAttribute("signatureNumeriqueRefId") != null ? Long.parseLong(String.valueOf(request.getAttribute("signatureNumeriqueRefId"))) : -1L;
    long demandeId = request.getAttribute("demandeId") != null ? (Long) request.getAttribute("demandeId") : 0L;
    
    String cheminPhotoWebcam = null;
    String cheminSignature = null;
    
    if (piecesFournies != null) {
        for (PieceFournie piece : piecesFournies) {
            if (piece == null || piece.getPiece_ref() == null) {
                continue;
            }
            long currentRefId = piece.getPiece_ref().getId();
            if (photoIdentiteRefId != -1L && photoIdentiteRefId == currentRefId) {
                cheminPhotoWebcam = ctx + "/demande/" + demandeId + "/piece/" + currentRefId + "/download";
            }
            if (signatureNumeriqueRefId != -1L && signatureNumeriqueRefId == currentRefId) {
                cheminSignature = ctx + "/demande/" + demandeId + "/piece/" + currentRefId + "/download";
            }
        }
    }
    
    String qrCodeWebUrl = (String) request.getAttribute("qrCodeWebUrl");
    String qrCodeFallbackWebUrl = (String) request.getAttribute("qrCodeFallbackWebUrl");
    boolean demandeComplete = Boolean.TRUE.equals(request.getAttribute("demandeComplete"));
    long dossierId = request.getAttribute("dossierId") != null ? (Long) request.getAttribute("dossierId") : 0L;
    String errorMsg = (String) request.getAttribute("error");
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiche de Demande de Visa - ${demande.refDemande}</title>
    
    <style>
        /* Variables de thème modernes */
        :root {
            --primary: #1e40af;
            --primary-light: #eff6ff;
            --secondary: #64748b;
            --background: #f8fafc;
            --surface: #ffffff;
            --border: #e2e8f0;
            --text-main: #0f172a;
            --text-muted: #475569;
            --danger: #ef4444;
            --danger-bg: #fef2f2;
            --radius: 8px;
        }

        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background-color: var(--background);
            color: var(--text-main);
            line-height: 1.5;
            margin: 0;
            padding: 2rem;
        }

        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: var(--surface);
            padding: 2.5rem;
            border-radius: var(--radius);
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
        }

        .header-title {
            text-align: center;
            color: var(--primary);
            font-size: 1.8rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 2px solid var(--border);
        }

        .section-title {
            font-size: 1.2rem;
            color: var(--primary);
            background-color: var(--primary-light);
            padding: 0.75rem 1rem;
            border-radius: var(--radius);
            margin: 2.5rem 0 1.5rem 0;
            display: flex;
            align-items: center;
            font-weight: 600;
        }

        /* Système de grille pour les informations */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 1rem;
        }

        .info-group {
            display: flex;
            flex-direction: column;
            background: var(--surface);
            padding: 0.5rem;
        }

        .info-label {
            font-size: 0.85rem;
            color: var(--text-muted);
            text-transform: uppercase;
            font-weight: 600;
            margin-bottom: 0.3rem;
        }

        .info-value {
            font-size: 1.05rem;
            font-weight: 500;
            color: var(--text-main);
            word-break: break-word;
        }

        /* Blocs spécifiques (Admin, Erreur, QR) */
        .card-admin {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            align-items: center;
            background-color: var(--primary-light);
            border: 1px solid #bfdbfe;
            padding: 1.5rem;
            border-radius: var(--radius);
            margin-bottom: 1.5rem;
        }

        .card-error {
            background-color: var(--danger-bg);
            border: 1px solid #fecaca;
            color: var(--danger);
            padding: 1rem;
            border-radius: var(--radius);
            margin-bottom: 1.5rem;
            font-weight: 500;
        }

        .qr-section {
            display: flex;
            align-items: center;
            gap: 2rem;
            padding: 1.5rem;
            border: 1px dashed var(--border);
            border-radius: var(--radius);
            margin-bottom: 2rem;
        }

        .qr-section img {
            width: 140px;
            height: 140px;
            padding: 0.5rem;
            background: white;
            border: 1px solid var(--border);
            border-radius: var(--radius);
        }

        /* Photos et Signatures */
        .profile-layout {
            display: grid;
            grid-template-columns: 1fr auto;
            gap: 2rem;
            align-items: start;
        }

        .photo-box {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 1rem;
            border: 1px solid var(--border);
            border-radius: var(--radius);
            background: #fafafa;
            min-width: 160px;
        }

        .photo-box img {
            max-width: 150px;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .placeholder-photo {
            width: 150px;
            height: 190px;
            border: 2px dashed #cbd5e1;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--secondary);
            font-size: 0.9rem;
            background: white;
            border-radius: 4px;
        }

        /* Pièces justificatives */
        .doc-list {
            list-style: none;
            padding: 0;
            margin: 0;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
        }

        .doc-item {
            display: flex;
            flex-direction: column;
            padding: 1rem;
            border: 1px solid var(--border);
            border-radius: var(--radius);
            background: var(--surface);
            transition: border-color 0.2s;
        }
        
        .doc-item:hover { border-color: var(--primary); }

        .doc-item a {
            color: var(--primary);
            text-decoration: none;
            font-size: 0.9rem;
            margin-top: 0.5rem;
            word-break: break-all;
        }

        /* Signatures Layout */
        .signature-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
        }

        .signature-box {
            border: 1px solid var(--border);
            padding: 1.5rem;
            border-radius: var(--radius);
            background: var(--surface);
            min-height: 150px;
            display: flex;
            flex-direction: column;
        }

        .signature-img {
            max-height: 80px;
            margin-top: 1rem;
            align-self: flex-start;
        }

        .badge {
            background: var(--primary);
            color: white;
            padding: 0.2rem 0.6rem;
            border-radius: 20px;
            font-size: 0.85rem;
        }

        @media print {
            body { background: white; padding: 0; }
            .container { box-shadow: none; padding: 0; max-width: 100%; }
            .qr-section, .card-admin { break-inside: avoid; }
        }
    </style>
</head>
<body>

<div class="container">
    <h1 class="header-title">Fiche de Demande de Visa</h1>

    <%-- Gestion des erreurs --%>
    <% if (errorMsg != null && !errorMsg.trim().isEmpty()) { %>
        <div class="card-error">
            <%= errorMsg %>
        </div>
    <% } %>

    <%-- Panneau d'administration --%>
    <div class="card-admin">
        <div class="info-group">
            <span class="info-label">Référence Unique</span>
            <span class="info-value">${demande.refDemande != null ? demande.refDemande : 'N/A'}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Statut</span>
            <span class="info-value"><span class="badge">${demande.statut.libelle}</span></span>
        </div>
        <div class="info-group">
            <span class="info-label">Dossier N°</span>
            <span class="info-value">${demande.dossier.id}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Scan Terminé</span>
            <span class="info-value">
                <input type="checkbox" disabled ${demande.dossier.scanTermine ? 'checked' : ''} style="transform: scale(1.3); margin-top: 5px;">
            </span>
        </div>
    </div>

    <%-- QR Code --%>
    <% 
        String qrPrimary = null;
        String qrFallback = null;
        String qrPrimarySrc = null;
        String qrFallbackSrc = null;
        if (qrCodeWebUrl != null && !qrCodeWebUrl.trim().isEmpty()) qrPrimary = qrCodeWebUrl.trim();
        if (qrCodeFallbackWebUrl != null && !qrCodeFallbackWebUrl.trim().isEmpty()) qrFallback = qrCodeFallbackWebUrl.trim();
        if (qrPrimary == null) qrPrimary = qrFallback;
        if (qrPrimary != null) {
            qrPrimarySrc = qrPrimary.startsWith("http://") || qrPrimary.startsWith("https://") ? qrPrimary : ctx + qrPrimary;
        }
        if (qrFallback != null) {
            qrFallbackSrc = qrFallback.startsWith("http://") || qrFallback.startsWith("https://") ? qrFallback : ctx + qrFallback;
        }
        if (qrPrimary != null) {
    %>
        <div class="qr-section">
            <img src="<%= qrPrimarySrc %>" alt="QR code de suivi" 
                 <%= (qrFallbackSrc != null && !qrFallbackSrc.equals(qrPrimarySrc)) ? "onerror=\"this.onerror=null;this.src='" + qrFallbackSrc + "';\"" : "" %> >
            <div>
                <h3 style="margin: 0 0 0.5rem 0; color: var(--primary);">QR code de suivi</h3>
                <p style="margin: 0 0 1rem 0; color: var(--text-muted); font-size: 0.9rem;">Scannez ce QR pour ouvrir la page de suivi de la demande.</p>
                <a href="<%= qrPrimarySrc %>" target="_blank" style="color: var(--primary); text-decoration: none; font-weight: 500;">Ouvrir le QR en grand</a>
                <p style="margin: 0.5rem 0 0 0; color: var(--secondary); font-size: 0.8rem; word-break: break-all;">URL: <%= qrPrimarySrc %></p>
            </div>
        </div>
    <% } %>

    <h2 class="section-title">1. Informations du Demandeur</h2>
    <div class="profile-layout">
        <div class="info-grid">
            <div class="info-group">
                <span class="info-label">Nom</span>
                <span class="info-value">${demande.demandeur.nom}</span>
            </div>
            <div class="info-group">
                <span class="info-label">Prénom(s)</span>
                <span class="info-value">${demande.demandeur.prenom}</span>
            </div>
            <div class="info-group">
                <span class="info-label">Nom de jeune fille</span>
                <span class="info-value">${not empty demande.demandeur.nomJeuneFille ? demande.demandeur.nomJeuneFille : '-'}</span>
            </div>
            <div class="info-group">
                <span class="info-label">Date de naissance</span>
                <span class="info-value">${not empty demande.demandeur.dateNaissance ? demande.demandeur.dateNaissance : '-'}</span>
            </div>
            <div class="info-group">
                <span class="info-label">Situation familiale</span>
                <span class="info-value">${demande.demandeur.situationFamille.libelle}</span>
            </div>
            <div class="info-group">
                <span class="info-label">Nationalité d'origine</span>
                <span class="info-value">${demande.demandeur.nationalite.libelle}</span>
            </div>
            <div class="info-group" style="grid-column: 1 / -1;">
                <span class="info-label">Profession</span>
                <span class="info-value">${demande.demandeur.profession}</span>
            </div>
            <div class="info-group" style="grid-column: 1 / -1;">
                <span class="info-label">Adresse à Madagascar</span>
                <span class="info-value">${demande.demandeur.adresseMadagascar}</span>
            </div>
            <div class="info-group" style="grid-column: 1 / -1;">
                <span class="info-label">Contact (Tél / Email)</span>
                <span class="info-value">${demande.demandeur.numeroTelephone} &nbsp;&bull;&nbsp; ${demande.demandeur.email}</span>
            </div>
        </div>
        
        <%-- Bloc Photo --%>
        <div class="photo-box">
            <span class="info-label" style="margin-bottom: 1rem;">Photo Identité</span>
            <% if (cheminPhotoWebcam != null && !cheminPhotoWebcam.isEmpty()) { %>
                <img src="<%= cheminPhotoWebcam %>" alt="Photo du demandeur">
            <% } else { %>
                <div class="placeholder-photo">Aucune capture</div>
            <% } %>
        </div>
    </div>

    <h2 class="section-title">2. Informations du Passeport</h2>
    <div class="info-grid">
        <div class="info-group">
            <span class="info-label">Numéro de passeport</span>
            <span class="info-value">${demande.passeport.numeroPasseport}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Pays de délivrance</span>
            <span class="info-value">${demande.passeport.paysDelivrance}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Date de délivrance</span>
            <span class="info-value">${not empty demande.passeport.dateDelivrance ? demande.passeport.dateDelivrance : '-'}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Date d'expiration</span>
            <span class="info-value">${not empty demande.passeport.dateExpiration ? demande.passeport.dateExpiration : '-'}</span>
        </div>
    </div>

    <h2 class="section-title">3. Détails de la Demande</h2>
    <div class="info-grid">
        <div class="info-group">
            <span class="info-label">Type de demande</span>
            <span class="info-value">${demande.typeDemande.libelle}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Document visé</span>
            <span class="info-value">${demande.typeDocument.libelle}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Lieu d'entrée prévu</span>
            <span class="info-value">${demande.visaLieuEntree}</span>
        </div>
        <div class="info-group">
            <span class="info-label">Période du visa</span>
            <span class="info-value">
                Du <strong>${not empty demande.visaDateEntree ? demande.visaDateEntree : '-'}</strong> 
                au <strong>${not empty demande.visaDateExpiration ? demande.visaDateExpiration : '-'}</strong>
            </span>
        </div>
    </div>

    <h2 class="section-title">4. Pièces Justificatives Associées</h2>
    <ul class="doc-list">
        <% 
            boolean hasDocs = false;
            if (piecesFournies != null && !piecesFournies.isEmpty()) {
                for (PieceFournie piece : piecesFournies) {
                            if (piece.getNom_fichier() != null && !piece.getNom_fichier().trim().isEmpty() &&
                                piece.getPiece_ref() != null &&
                                piece.getPiece_ref().getId() != photoIdentiteRefId && 
                                piece.getPiece_ref().getId() != signatureNumeriqueRefId) {
                        
                        hasDocs = true;
        %>
            <li class="doc-item">
                <span class="info-label"><%= piece.getPiece_ref().getLibelle() %></span>
                <a href="<%= ctx %>/<%= piece.getChemin_fichier() %>" target="_blank">
                    <svg style="width:16px; height:16px; vertical-align:middle; margin-right:5px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"></path></svg>
                    <%= piece.getNom_fichier() %>
                </a>
            </li>
        <% 
                    }
                }
            }
            if (!hasDocs) { 
        %>
            <li style="color: var(--text-muted); font-style: italic;">Aucune pièce fournie pour le moment.</li>
        <% } %>
    </ul>

    <h2 class="section-title">5. Signatures et Validation</h2>
    <div class="signature-grid">
        <div class="signature-box">
            <span class="info-label">Signature du Demandeur</span>
            <span style="color: var(--text-muted); font-size: 0.85rem;">Je certifie l'exactitude des informations fournies.</span>
            
            <% if (cheminSignature != null && !cheminSignature.isEmpty()) { %>
                <img src="<%= cheminSignature %>" alt="Signature" class="signature-img">
            <% } else { %>
                <div style="margin-top: 1.5rem; color: #94a3b8; font-style: italic;">[Aucune signature]</div>
            <% } %>
        </div>
        
        <div class="signature-box" style="background-color: var(--background);">
            <span class="info-label">Cadre réservé à l'Agent</span>
            <div style="margin-top: 1rem; color: var(--text-muted); font-size: 0.95rem;">
                <p>Date de traitement : <strong>___/___/20___</strong></p>
                <label style="display: flex; align-items: center; gap: 0.5rem; margin-top: 1rem; cursor: not-allowed;">
                    <input type="checkbox" disabled ${demande.verrouille ? 'checked' : ''} style="transform: scale(1.2);">
                    <strong>Dossier Verrouillé</strong>
                </label>
            </div>
        </div>
    </div>
</div>

</body>
</html>