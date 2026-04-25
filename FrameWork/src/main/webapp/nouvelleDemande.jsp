<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="models.TypeDemande" %>
<%@ page import="models.SituationFamille" %>
<%@ page import="models.Nationalite" %>
<%@ page import="models.PieceJustificative" %>

<%
    String ctx = request.getContextPath();
    @SuppressWarnings("unchecked")
    Map<String, Object> formData = (Map<String, Object>) request.getAttribute("formData");
    if (formData == null) formData = new java.util.HashMap<>();

    boolean editMode = Boolean.TRUE.equals(request.getAttribute("editMode"));
    String formAction = editMode ? (ctx + "/form/update") : (ctx + "/form/save");
    String submitLabel = editMode ? "Mettre a jour" : "Soumettre";
    String pageTitle = editMode ? "Modifier la Demande de Visa" : "Nouvelle Demande de Visa Transformable";

    @SuppressWarnings("unchecked")
    List<Long> selectedPieceIds = (List<Long>) request.getAttribute("selectedPieceIds");
    if (selectedPieceIds == null) selectedPieceIds = new ArrayList<>();

    String selectedTypeDemande = formData.get("typeDemande") != null ? String.valueOf(formData.get("typeDemande")) : "";
    String selectedSituationFamille = formData.get("situationFamilleId") != null ? String.valueOf(formData.get("situationFamilleId")) : "";
    String selectedNationalite = formData.get("nationaliteId") != null ? String.valueOf(formData.get("nationaliteId")) : "";
    String selectedProfil = formData.get("profil") != null ? String.valueOf(formData.get("profil")) : "";
%>
<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset="UTF-8">
    <title><%= pageTitle %></title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<div class="container">
    <header>
        <h1><%= pageTitle %></h1>
        <p>Recherche demandeur puis creation d'une demande (visa, titre de residence, duplicata) avec validation metier cote front.</p>
    </header>

    <% if (request.getAttribute("message") != null) { %>
        <div class="success-banner"><%= request.getAttribute("message") %></div>
    <% } %>

    <% if (request.getAttribute("error") != null) { %>
        <div class="error-banner"><%= request.getAttribute("error") %></div>
    <% } %>

    <div id="globalMessage" class="hidden" role="alert" aria-live="assertive"></div>

    <div class="form-section search-section">
        <h2>Recherche demandeur</h2>
        <p class="hint-text">Renseignez au moins le numero de passeport ou le triplet nom / prenom / date de naissance.</p>
        <div class="form-row">
            <div class="form-group">
                <label for="searchNom">Nom</label>
                <input type="text" id="searchNom" placeholder="Ex: RAKOTO" autocomplete="off">
            </div>
            <div class="form-group">
                <label for="searchPrenom">Prenom</label>
                <input type="text" id="searchPrenom" placeholder="Ex: Aina" autocomplete="off">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label for="searchDateNaissance">Date de naissance</label>
                <input type="date" id="searchDateNaissance">
            </div>
            <div class="form-group">
                <label for="searchNumeroPasseport">Numero passeport</label>
                <input type="text" id="searchNumeroPasseport" placeholder="Ex: M123456" autocomplete="off">
            </div>
        </div>
        <div class="search-actions-row">
            <button type="button" id="runRechercheBtn" class="btn-alt">Rechercher</button>
            <span id="searchStatusText" class="hint-text"></span>
        </div>

        <div id="searchFound" class="search-result success-banner hidden">
            <h3>Demandeur trouve</h3>
            <div class="result-grid">
                <div>
                    <h4>Infos demandeur</h4>
                    <ul class="meta-list compact" id="foundDemandeurInfo"></ul>
                </div>
                <div>
                    <h4>Infos passeport</h4>
                    <ul class="meta-list compact" id="foundPasseportInfo"></ul>
                </div>
            </div>
            <div class="search-actions-row">
                <button type="button" id="useFoundDataBtn">Reutiliser ces informations</button>
                <label for="nextTypeDemande" class="inline-label">Nouvelle demande</label>
                <select id="nextTypeDemande"></select>
                <button type="button" id="applyNextTypeBtn" class="btn-alt">Appliquer</button>
            </div>
        </div>

        <div id="searchNotFound" class="search-result warning-banner hidden">
            Aucun demandeur trouve, veuillez remplir le formulaire pour creer une nouvelle demande.
        </div>
    </div>

    <form id="demandeForm" action="<%= formAction %>" method="post" novalidate>
        <% if (editMode) { %>
            <input type="hidden" name="demande_id" value="<%= formData.get("demande_id") != null ? formData.get("demande_id") : "" %>">
            <input type="hidden" name="passeport_id" value="<%= formData.get("passeport_id") != null ? formData.get("passeport_id") : "" %>">
        <% } %>

        <div id="sectionTypeDemande" class="form-section">
            <h2>Type de demande</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="typeDemande">Type de demande <span class="required">*</span></label>
                    <select id="typeDemande" name="typeDemande" required>
                        <option value="">Sélectionner</option>
                        <%
                        List<TypeDemande> typesDemandeOptions = (List<TypeDemande>) request.getAttribute("typesDemandeOptions");
                        if (typesDemandeOptions != null) {
                            for (TypeDemande td : typesDemandeOptions) {
                        %>
                            <option value="<%= td.getId() %>" <%= String.valueOf(td.getId()).equals(selectedTypeDemande) ? "selected" : "" %>><%= td.getLibelle() %></option>
                        <%
                            }
                        }
                        %>
                    </select>
                    <div id="typeDemandeError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label>Profil <span class="required">*</span></label>
                    <div class="form-row">
                        <label><input type="radio" name="profil" value="investisseur" <%= "investisseur".equalsIgnoreCase(selectedProfil) ? "checked" : "" %>> Investisseur</label>
                        <label><input type="radio" name="profil" value="travailleur" <%= "travailleur".equalsIgnoreCase(selectedProfil) ? "checked" : "" %>> Travailleur</label>
                    </div>
                    <div id="profilError" class="error-text"></div>
                </div>
            </div>
            <p class="hint-text">Si le type est <strong>Duplicata</strong>, le bloc duplicata ci-dessous devient obligatoire.</p>
        </div>

        <div id="sectionEtatCivil" class="form-section hidden">
            <h2>État civil</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="nom">Nom <span class="required">*</span></label>
                    <input type="text" id="nom" name="nom" value="<%= formData.get("nom") != null ? formData.get("nom") : "" %>" required>
                    <div id="nomError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="prenom">Prénom</label>
                    <input type="text" id="prenom" name="prenom" value="<%= formData.get("prenom") != null ? formData.get("prenom") : "" %>">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="nomJeuneFille">Nom de jeune fille</label>
                    <input type="text" id="nomJeuneFille" name="nomJeuneFille" value="<%= formData.get("nomJeuneFille") != null ? formData.get("nomJeuneFille") : "" %>">
                    <div id="nomJeuneFilleError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="dateNaissance">Date de naissance <span class="required">*</span></label>
                    <input type="date" id="dateNaissance" name="dateNaissance" value="<%= formData.get("dateNaissance") != null ? formData.get("dateNaissance") : "" %>" required>
                    <div id="dateNaissanceError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="situationFamille">Situation de famille <span class="required">*</span></label>
                    <select id="situationFamille" name="situationFamilleId" required>
                        <option value="">Sélectionner</option>
                        <%
                        List<SituationFamille> situationsFamille = (List<SituationFamille>) request.getAttribute("situationsFamille");
                        if (situationsFamille != null) {
                            for (SituationFamille sf : situationsFamille) {
                        %>
                            <option value="<%= sf.getId() %>" <%= String.valueOf(sf.getId()).equals(selectedSituationFamille) ? "selected" : "" %>><%= sf.getLibelle() %></option>
                        <%
                            }
                        }
                        %>
                    </select>
                    <div id="situationFamilleError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="nationalite">Nationalité <span class="required">*</span></label>
                    <select id="nationalite" name="nationaliteId" required>
                        <option value="">Sélectionner</option>
                        <%
                        List<Nationalite> nationalites = (List<Nationalite>) request.getAttribute("nationalites");
                        if (nationalites != null) {
                            for (Nationalite nat : nationalites) {
                        %>
                            <option value="<%= nat.getId() %>" <%= String.valueOf(nat.getId()).equals(selectedNationalite) ? "selected" : "" %>><%= nat.getLibelle() %></option>
                        <%
                            }
                        }
                        %>
                    </select>
                    <div id="nationaliteError" class="error-text"></div>
                </div>
            </div>
            <div class="form-group">
                <label for="adresseMadagascar">Adresse à Madagascar <span class="required">*</span></label>
                <textarea id="adresseMadagascar" name="adresseMadagascar" required><%= formData.get("adresseMadagascar") != null ? formData.get("adresseMadagascar") : "" %></textarea>
                <div id="adresseMadagascarError" class="error-text"></div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="numeroTelephone">Numéro de téléphone <span class="required">*</span></label>
                    <input type="tel" id="numeroTelephone" name="numeroTelephone" value="<%= formData.get("numeroTelephone") != null ? formData.get("numeroTelephone") : "" %>" required>
                    <div id="numeroTelephoneError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" value="<%= formData.get("email") != null ? formData.get("email") : "" %>">
                </div>
            </div>
            <div class="form-group">
                <label for="profession">Profession <span class="required">*</span></label>
                <input type="text" id="profession" name="profession" value="<%= formData.get("profession") != null ? formData.get("profession") : "" %>" required>
                <div id="professionError" class="error-text"></div>
            </div>
        </div>

        <div id="sectionPasseport" class="form-section hidden">
            <h2>Passeport</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="numeroPasseport">Numéro de passeport <span class="required">*</span></label>
                    <input type="text" id="numeroPasseport" name="numeroPasseport" value="<%= formData.get("numeroPasseport") != null ? formData.get("numeroPasseport") : "" %>" required>
                    <div id="numeroPasseportError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="dateDelivrance">Date de délivrance <span class="required">*</span></label>
                    <input type="date" id="dateDelivrance" name="dateDelivrance" value="<%= formData.get("dateDelivrance") != null ? formData.get("dateDelivrance") : "" %>" required>
                    <div id="dateDelivranceError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="dateExpiration">Date d'expiration <span class="required">*</span></label>
                    <input type="date" id="dateExpiration" name="dateExpiration" value="<%= formData.get("dateExpiration") != null ? formData.get("dateExpiration") : "" %>" required>
                    <div id="dateExpirationError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="paysDelivrance">Pays de délivrance <span class="required">*</span></label>
                    <input type="text" id="paysDelivrance" name="paysDelivrance" value="<%= formData.get("paysDelivrance") != null ? formData.get("paysDelivrance") : "" %>" required>
                    <div id="paysDelivranceError" class="error-text"></div>
                </div>
            </div>
        </div>

        <div id="sectionVisa" class="form-section hidden">
            <h2>Visa</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="visaDateEntree">Date d'entrée <span class="required">*</span></label>
                    <input type="date" id="visaDateEntree" name="visaDateEntree" value="<%= formData.get("visaDateEntree") != null ? formData.get("visaDateEntree") : "" %>" required>
                    <div id="visaDateEntreeError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="visaLieuEntree">Lieu d'entrée <span class="required">*</span></label>
                    <input type="text" id="visaLieuEntree" name="visaLieuEntree" value="<%= formData.get("visaLieuEntree") != null ? formData.get("visaLieuEntree") : "" %>" required>
                    <div id="visaLieuEntreeError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="visaDateExpiration">Date d'expiration <span class="required">*</span></label>
                    <input type="date" id="visaDateExpiration" name="visaDateExpiration" value="<%= formData.get("visaDateExpiration") != null ? formData.get("visaDateExpiration") : "" %>" required>
                    <div id="visaDateExpirationError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="categorieDemande">Catégorie de demande <span class="required">*</span></label>
                    <select id="categorieDemande" name="categorieDemande" required>
                        <option value="">Sélectionner</option>
                        <option value="Nouveau titre" <%= "Nouveau titre".equals(String.valueOf(formData.get("categorieDemande"))) ? "selected" : "" %>>Nouveau titre</option>
                        <option value="Duplicata" <%= "Duplicata".equals(String.valueOf(formData.get("categorieDemande"))) ? "selected" : "" %>>Duplicata</option>
                        <option value="Transfert visa" <%= "Transfert visa".equals(String.valueOf(formData.get("categorieDemande"))) ? "selected" : "" %>>Transfert visa</option>
                    </select>
                    <div id="categorieDemandeError" class="error-text"></div>
                </div>
            </div>
        </div>

        <div id="duplicataBlock" class="form-section hidden">
            <h2>Bloc duplicata</h2>
            <div class="form-row">
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="visaApprouveConfirme" name="visaApprouveConfirme" value="true" <%= "true".equalsIgnoreCase(String.valueOf(formData.get("visaApprouveConfirme"))) ? "checked" : "" %>>
                        Le demandeur confirme qu'il avait deja un visa approuve <span class="required">*</span>
                    </label>
                    <div id="visaApprouveConfirmeError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="typeDocument">Type de document <span class="required">*</span></label>
                    <select id="typeDocument" name="typeDocument">
                        <option value="">Selectionner</option>
                        <option value="Titre de residence" selected>Titre de residence</option>
                    </select>
                    <div id="typeDocumentError" class="error-text"></div>
                </div>
            </div>
            <div class="form-group">
                <label for="previousDemandeRef">Ancienne reference (optionnel)</label>
                <input type="text" id="previousDemandeRef" name="previousDemandeRef" value="<%= formData.get("previousDemandeRef") != null ? formData.get("previousDemandeRef") : "" %>" placeholder="Ex: 20240112-102233-VISA">
            </div>
            <div class="form-group">
                <label for="mentionDossier">Mention dossier</label>
                <input type="text" id="mentionDossier" readonly value="Duplicata - antecedent non retrouve">
            </div>
            <div id="duplicataPieceError" class="error-text"></div>
        </div>

        <div id="piecesCommunes" class="form-section hidden">
            <h2>Pièces justificatives communes <span class="required">*</span></h2>
            <div class="select-all-row">
                <label>
                    <input type="checkbox" class="js-select-all-pieces" data-target-section="piecesCommunes">
                    Tout sélectionner
                </label>
            </div>
            <div class="checkbox-group">
                <%
                List<PieceJustificative> piecesCommunes = (List<PieceJustificative>) request.getAttribute("piecesCommunes");
                if (piecesCommunes != null) {
                    for (PieceJustificative piece : piecesCommunes) {
                %>
                    <div class="checkbox-item">
                        <label>
                            <input type="checkbox" name="piece_ids" class="required-piece" data-required="true" value="<%= piece.getId() %>" <%= selectedPieceIds.contains(piece.getId()) ? "checked" : "" %>>
                            <%= piece.getLibelle() %> <span class="required">*</span>
                        </label>
                    </div>
                <%
                    }
                }
                %>
            </div>
            <div id="pieceCommuneError" class="error-text"></div>
        </div>

        <div id="piecesInvestisseur" class="form-section hidden">
            <h2>Pièces Investisseur <span class="required">*</span></h2>
            <div class="select-all-row">
                <label>
                    <input type="checkbox" class="js-select-all-pieces" data-target-section="piecesInvestisseur">
                    Tout sélectionner
                </label>
            </div>
            <div class="checkbox-group">
                <%
                List<PieceJustificative> piecesInvestisseur = (List<PieceJustificative>) request.getAttribute("piecesInvestisseur");
                if (piecesInvestisseur != null) {
                    for (PieceJustificative piece : piecesInvestisseur) {
                %>
                    <div class="checkbox-item">
                        <label>
                            <input type="checkbox" name="piece_ids" class="required-piece" data-required="true" value="<%= piece.getId() %>" <%= selectedPieceIds.contains(piece.getId()) ? "checked" : "" %>>
                            <%= piece.getLibelle() %> <span class="required">*</span>
                        </label>
                    </div>
                <%
                    }
                }
                %>
            </div>
            <div id="pieceInvestisseurError" class="error-text"></div>
        </div>

        <div id="piecesTravailleur" class="form-section hidden">
            <h2>Pièces Travailleur <span class="required">*</span></h2>
            <div class="select-all-row">
                <label>
                    <input type="checkbox" class="js-select-all-pieces" data-target-section="piecesTravailleur">
                    Tout sélectionner
                </label>
            </div>
            <div class="checkbox-group">
                <%
                List<PieceJustificative> piecesTravailleur = (List<PieceJustificative>) request.getAttribute("piecesTravailleur");
                if (piecesTravailleur != null) {
                    for (PieceJustificative piece : piecesTravailleur) {
                %>
                    <div class="checkbox-item">
                        <label>
                            <input type="checkbox" name="piece_ids" class="required-piece" data-required="true" value="<%= piece.getId() %>" <%= selectedPieceIds.contains(piece.getId()) ? "checked" : "" %>>
                            <%= piece.getLibelle() %> <span class="required">*</span>
                        </label>
                    </div>
                <%
                    }
                }
                %>
            </div>
            <div id="pieceTravailleurError" class="error-text"></div>
        </div>

        <div class="form-actions">
            <button type="button" id="reviewBtn" disabled>Voir le recapitulatif</button>
            <button type="submit" id="submitBtn" class="hidden"><%= submitLabel %></button>
        </div>

        <div id="recapSection" class="form-section hidden" aria-live="polite">
            <h2>Recapitulatif avant soumission</h2>
            <p class="hint-text">Verifiez les informations ci-dessous. Vous pouvez revenir en modification avant la confirmation finale.</p>

            <div class="result-grid">
                <div>
                    <h3>Demandeur</h3>
                    <ul id="recapDemandeur" class="meta-list compact"></ul>
                </div>
                <div>
                    <h3>Demande</h3>
                    <ul id="recapDemande" class="meta-list compact"></ul>
                </div>
            </div>

            <div style="margin-top: 16px;">
                <h3>Pieces justificatives cochees</h3>
                <ul id="recapPieces" class="meta-list compact"></ul>
            </div>

            <div class="form-actions" style="margin-top: 20px;">
                <button type="button" id="backToEditBtn" class="btn-alt">Modifier mes donnees</button>
                <button type="button" id="confirmSubmitBtn">Soumettre la demande</button>
            </div>
        </div>
    </form>
</div>

<script src="<%= ctx %>/js/dynamicFields.js"></script>
<script src="<%= ctx %>/js/validation.js"></script>
<script src="<%= ctx %>/js/searchFlow.js"></script>
<script src="<%= ctx %>/js/recap.js"></script>
</body>
</html>