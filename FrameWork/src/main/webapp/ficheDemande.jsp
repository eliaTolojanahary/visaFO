<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>

<%@ page import="java.util.Map" %>
<%@ page import="models.PieceFournie" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<% String ctx = request.getContextPath(); %>
<%
Map<String, Object> demande = (Map<String, Object>) request.getAttribute("demande");
List<PieceFournie> piecesFournies = (List<PieceFournie>) request.getAttribute("piecesFournies");
Long photoIdentiteRefId = request.getAttribute("photoIdentiteRefId") != null ? Long.valueOf(String.valueOf(request.getAttribute("photoIdentiteRefId"))) : null;
Long signatureNumeriqueRefId = request.getAttribute("signatureNumeriqueRefId") != null ? Long.valueOf(String.valueOf(request.getAttribute("signatureNumeriqueRefId"))) : null;
long demandeId = request.getAttribute("demandeId") != null ? (Long) request.getAttribute("demandeId") : 0L;
String cheminPhotoWebcam = null;
String cheminSignature = null;
if (piecesFournies != null) {
    for (PieceFournie piece : piecesFournies) {
        if (piece == null || piece.getPiece_ref() == null) {
            continue;
        }
        Long currentRefId = piece.getPiece_ref().getId();
        if (photoIdentiteRefId != null && photoIdentiteRefId.equals(currentRefId)) {
            cheminPhotoWebcam = ctx + "/demande/" + demandeId + "/piece/" + currentRefId + "/download";
        }
        if (signatureNumeriqueRefId != null && signatureNumeriqueRefId.equals(currentRefId)) {
            cheminSignature = ctx + "/demande/" + demandeId + "/piece/" + currentRefId + "/download";
        }
    }
}
request.setAttribute("cheminPhotoWebcam", cheminPhotoWebcam);
request.setAttribute("cheminSignature", cheminSignature);
String qrCodeWebUrl = (String) request.getAttribute("qrCodeWebUrl");
boolean demandeComplete = Boolean.TRUE.equals(request.getAttribute("demandeComplete"));
long dossierId = request.getAttribute("dossierId") != null ? (Long) request.getAttribute("dossierId") : 0L;
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiche de Demande de Visa - ${demande.refDemande}</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">    
    <style>
        :root {
            --primary-color: #2c3e50;
            --border-color: #bdc3c7;
            --bg-light: #ecf0f1;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: #333;
            line-height: 1.6;
            background-color: #f9f9f9;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: #fff;
            padding: 30px;
            border: 1px solid var(--border-color);
            box-shadow: 0 0 10px rgba(0,0,0,0.05);
        }
        h1 {
            text-align: center;
            color: var(--primary-color);
            border-bottom: 2px solid var(--primary-color);
            padding-bottom: 10px;
            text-transform: uppercase;
            font-size: 24px;
        }
        h2 {
            font-size: 18px;
            color: var(--primary-color);
            background-color: var(--bg-light);
            padding: 8px;
            margin-top: 25px;
            border-left: 4px solid var(--primary-color);
        }
        .admin-block {
            border: 2px dashed #e74c3c;
            padding: 15px;
            background-color: #fff9f9;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        th, td {
            border: 1px solid var(--border-color);
            padding: 10px;
            vertical-align: middle;
        }
        th {
            background-color: var(--bg-light);
            text-align: left;
            width: 35%;
        }
        .photo-box {
            text-align: center;
            width: 150px;
        }
        .photo-box img {
            max-width: 140px;
            max-height: 175px;
            border: 1px solid var(--border-color);
        }
        .placeholder-photo {
            width: 140px;
            height: 175px;
            border: 2px dashed #999;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto;
            color: #7f8c8d;
            font-size: 12px;
        }
        .signature-box {
            height: 120px;
            position: relative;
        }
        .signature-img {
            max-height: 80px;
            max-width: 100%;
        }
        @media print {
            body { background: white; padding: 0; }
            .container { box-shadow: none; border: none; }
        }
    </style>
</head>
<body>

<div class="container">
    <h1>Fiche de Demande de Visa</h1>

    <c:if test="${not empty error}">
        <div class="admin-block" style="border-color:#c0392b; background:#fff4f4; color:#922b21;">
            ${error}
        </div>
    </c:if>

    <div class="admin-block">
        <strong>Référence Unique :</strong> ${demande.refDemande != null ? demande.refDemande : 'N/A'} <br>
        <strong>Statut :</strong> <span class="badge">${demande.statut.libelle}</span> <br>
        <strong>Dossier N° :</strong> ${demande.dossier.id} 
        <span style="float: right;">
            <strong>Scan Terminé :</strong> 
            <input type="checkbox" disabled <c:if test="${demande.dossier.scanTermine}">checked</c:if> >
        </span>
    </div>

    <h2>1. Informations du Demandeur</h2>
    <table>
        <tr>
            <th>Nom</th>
            <td>${demande.demandeur.nom}</td>
            <td rowspan="6" class="photo-box">
                <strong>PHOTO IDENTITÉ</strong><br><br>
                <c:choose>
                    <c:when test="${not empty cheminPhotoWebcam}">
                        <img src="<%= cheminPhotoWebcam %>" alt="Photo de ${demande.demandeur.nom}">
                    </c:when>
                    <c:otherwise>
                        <div class="placeholder-photo">[Aucune capture]</div>
                    </c:otherwise>
                </c:choose>
            </td>
        </tr>
        <tr>
            <th>Prénom(s)</th>
            <td>${demande.demandeur.prenom}</td>
        </tr>
        <tr>
            <th>Nom de jeune fille</th>
            <td>${not empty demande.demandeur.nomJeuneFille ? demande.demandeur.nomJeuneFille : '-'}</td>
        </tr>
        <tr>
            <th>Date de naissance</th>
            <td>${not empty demande.demandeur.dateNaissance ? demande.demandeur.dateNaissance : '-'}</td>
        </tr>
        <tr>
            <th>Situation familiale</th>
            <td>${demande.demandeur.situationFamille.libelle}</td>
        </tr>
        <tr>
            <th>Nationalité d'origine</th>
            <td>${demande.demandeur.nationalite.libelle}</td>
        </tr>
        <tr>
            <th>Profession</th>
            <td colspan="2">${demande.demandeur.profession}</td>
        </tr>
        <tr>
            <th>Adresse à Madagascar</th>
            <td colspan="2">${demande.demandeur.adresseMadagascar}</td>
        </tr>
        <tr>
            <th>Contact (Tél / Email)</th>
            <td colspan="2">${demande.demandeur.numeroTelephone} / ${demande.demandeur.email}</td>
        </tr>
    </table>

    <h2>2. Informations du Passeport</h2>
    <table>
        <tr>
            <th>Numéro de passeport</th>
            <td>${demande.passeport.numeroPasseport}</td>
            <th>Pays de délivrance</th>
            <td>${demande.passeport.paysDelivrance}</td>
        </tr>
        <tr>
            <th>Date de délivrance</th>
            <td>${not empty demande.passeport.dateDelivrance ? demande.passeport.dateDelivrance : '-'}</td>
            <th>Date d'expiration</th>
            <td>${not empty demande.passeport.dateExpiration ? demande.passeport.dateExpiration : '-'}</td>
        </tr>
    </table>

    <h2>3. Détails de la Demande</h2>
    <table>
        <tr>
            <th>Type de demande</th>
            <td>${demande.typeDemande.libelle}</td>
            <th>Document visé</th>
            <td>${demande.typeDocument.libelle}</td>
        </tr>
        <tr>
            <th>Lieu d'entrée prévu</th>
            <td>${demande.visaLieuEntree}</td>
            <th>Période du visa</th>
            <td>
                Du ${not empty demande.visaDateEntree ? demande.visaDateEntree : '-'} 
                au ${not empty demande.visaDateExpiration ? demande.visaDateExpiration : '-'}
            </td>
        </tr>
    </table>

    <h2>4. Pièces Justificatives Associées</h2>
    <ul>
        <c:choose>
            <c:when test="${not empty piecesFournies}">
                <c:forEach var="piece" items="${piecesFournies}">
                        <c:if test="${not empty piece.nom_fichier and piece.piece_ref.id ne photoIdentiteRefId and piece.piece_ref.id ne signatureNumeriqueRefId}">
                    <li>
                        <strong>${piece.piece_ref.libelle}</strong>
                            <br><small style="color: gray;">(Fichier : <a href="${pageContext.request.contextPath}/${piece.chemin_fichier}" target="_blank">${piece.nom_fichier}</a>)</small>
                    </li>
                        </c:if>
                </c:forEach>
            </c:when>
            <c:otherwise>
                <li><em>Aucune pièce fournie pour le moment.</em></li>
            </c:otherwise>
        </c:choose>
    </ul>

    <h2>5. Signatures et Validation</h2>
    <table>
        <tr>
            <td style="width: 50%; vertical-align: top;" class="signature-box">
                <strong>Signature du Demandeur</strong><br>
                <small style="color: #666;">Je certifie l'exactitude des informations fournies.</small><br><br>
                <c:if test="${not empty cheminSignature}">
                    <img src="<%= cheminSignature %>" alt="Signature" class="signature-img">
                </c:if>
            </td>
            <td style="width: 50%; vertical-align: top;">
                <strong>Cadre réservé à l'Agent (Validation)</strong><br>
                <small style="color: #666;">Date de traitement : ___/___/20___</small><br><br>
                <small style="color: #666;">Dossier Verrouillé : 
                    <input type="checkbox" disabled <c:if test="${demande.verrouille}">checked</c:if> >
                </small>
            </td>
        </tr>
    </table>
</div>

</body>
</html>