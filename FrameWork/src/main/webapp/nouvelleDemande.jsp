<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Nouvelle Demande de Visa Transformable</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="container">
    <header>
        <h1>Nouvelle Demande de Visa Transformable</h1>
        <p>Formulaire pour la demande de Nouveau titre, avec affichage conditionnel des champs selon le profil.</p>
    </header>

    <c:if test="${not empty error}">
        <div id="globalMessage" class="error-banner">${error}</div>
    </c:if>

    <div id="globalMessage" class="hidden"></div>

    <form id="demandeForm" action="${pageContext.request.contextPath}/visa/form" method="post" novalidate>
        <div class="form-section">
            <h2>Type de demande</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="typeDemande">Type de demande <span class="required">*</span></label>
                    <select id="typeDemande" name="typeDemande" required>
                        <option value="">Sélectionner</option>
                        <option value="Nouveau titre" <c:if test="${demande.typeDemande == 'Nouveau titre'}">selected</c:if>>Nouveau titre</option>
                        <option value="Duplicata" <c:if test="${demande.typeDemande == 'Duplicata'}">selected</c:if>>Duplicata</option>
                        <option value="Transfert de visa" <c:if test="${demande.typeDemande == 'Transfert de visa'}">selected</c:if>>Transfert de visa</option>
                    </select>
                    <div id="typeDemandeError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label>Profil <span class="required">*</span></label>
                    <div class="form-row">
                        <label><input type="radio" name="profil" value="investisseur"> Investisseur</label>
                        <label><input type="radio" name="profil" value="travailleur"> Travailleur</label>
                    </div>
                    <div id="profilError" class="error-text"></div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <h2>État civil</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="nom">Nom <span class="required">*</span></label>
                    <input type="text" id="nom" name="nom" value="${demandeur.nom}" required>
                    <div id="nomError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="prenom">Prénom</label>
                    <input type="text" id="prenom" name="prenom" value="${demandeur.prenom}">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="nomJeuneFille">Nom de jeune fille <span class="required">*</span></label>
                    <input type="text" id="nomJeuneFille" name="nomJeuneFille" value="${demandeur.nomJeuneFille}" required>
                    <div id="nomJeuneFilleError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="dateNaissance">Date de naissance <span class="required">*</span></label>
                    <input type="date" id="dateNaissance" name="dateNaissance" value="${demandeur.dateNaissance}" required>
                    <div id="dateNaissanceError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="situationFamille">Situation de famille <span class="required">*</span></label>
                    <select id="situationFamille" name="situationFamilleId" required>
                        <option value="">Sélectionner</option>
                        <c:forEach var="sf" items="${situationsFamille}">
                            <option value="${sf.id}" <c:if test="${demandeur.situationFamilleId == sf.id}">selected</c:if>>${sf.libelle}</option>
                        </c:forEach>
                    </select>
                    <div id="situationFamilleError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="nationalite">Nationalité <span class="required">*</span></label>
                    <select id="nationalite" name="nationaliteId" required>
                        <option value="">Sélectionner</option>
                        <c:forEach var="nat" items="${nationalites}">
                            <option value="${nat.id}" <c:if test="${demandeur.nationaliteId == nat.id}">selected</c:if>>${nat.libelle}</option>
                        </c:forEach>
                    </select>
                    <div id="nationaliteError" class="error-text"></div>
                </div>
            </div>
            <div class="form-group">
                <label for="adresseMadagascar">Adresse à Madagascar <span class="required">*</span></label>
                <textarea id="adresseMadagascar" name="adresseMadagascar" required>${demandeur.adresseMadagascar}</textarea>
                <div id="adresseMadagascarError" class="error-text"></div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="numeroTelephone">Numéro de téléphone <span class="required">*</span></label>
                    <input type="tel" id="numeroTelephone" name="numeroTelephone" value="${demandeur.numeroTelephone}" required>
                    <div id="numeroTelephoneError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" value="${demandeur.email}">
                </div>
            </div>
            <div class="form-group">
                <label for="profession">Profession <span class="required">*</span></label>
                <input type="text" id="profession" name="profession" value="${demandeur.profession}" required>
                <div id="professionError" class="error-text"></div>
            </div>
        </div>

        <div class="form-section">
            <h2>Passeport</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="numeroPasseport">Numéro de passeport <span class="required">*</span></label>
                    <input type="text" id="numeroPasseport" name="numeroPasseport" value="${passeport.numeroPasseport}" required>
                    <div id="numeroPasseportError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="dateDelivrance">Date de délivrance <span class="required">*</span></label>
                    <input type="date" id="dateDelivrance" name="dateDelivrance" value="${passeport.dateDelivrance}" required>
                    <div id="dateDelivranceError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="dateExpiration">Date d'expiration <span class="required">*</span></label>
                    <input type="date" id="dateExpiration" name="dateExpiration" value="${passeport.dateExpiration}" required>
                    <div id="dateExpirationError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="paysDelivrance">Pays de délivrance <span class="required">*</span></label>
                    <input type="text" id="paysDelivrance" name="paysDelivrance" value="${passeport.paysDelivrance}" required>
                    <div id="paysDelivranceError" class="error-text"></div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <h2>Visa</h2>
            <div class="form-row">
                <div class="form-group">
                    <label for="visaDateEntree">Date d'entrée <span class="required">*</span></label>
                    <input type="date" id="visaDateEntree" name="visaDateEntree" value="${demande.visaDateEntree}" required>
                    <div id="visaDateEntreeError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="visaLieuEntree">Lieu d'entrée <span class="required">*</span></label>
                    <input type="text" id="visaLieuEntree" name="visaLieuEntree" value="${demande.visaLieuEntree}" required>
                    <div id="visaLieuEntreeError" class="error-text"></div>
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="visaDateExpiration">Date d'expiration <span class="required">*</span></label>
                    <input type="date" id="visaDateExpiration" name="visaDateExpiration" value="${demande.visaDateExpiration}" required>
                    <div id="visaDateExpirationError" class="error-text"></div>
                </div>
                <div class="form-group">
                    <label for="categorieDemande">Catégorie de demande <span class="required">*</span></label>
                    <select id="categorieDemande" name="categorieDemande" required>
                        <option value="">Sélectionner</option>
                        <option value="Nouveau titre" selected>Nouveau titre</option>
                    </select>
                    <div id="categorieDemandeError" class="error-text"></div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <h2>Pièces justificatives communes</h2>
            <div class="checkbox-group">
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="photos"> 02 photos d'identité</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="notice"> Notice de renseignement</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="demandeMinistere"> Demande adressée au Ministre</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="visaValide"> Photocopie du visa en cours de validité</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="passeport"> Photocopie de la 1ère page du passeport</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="carteResident"> Photocopie de la carte de résident</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="certificatResidence"> Certificat de résidence à Madagascar</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceCommune" value="casierJudiciaire"> Extrait de casier judiciaire &lt; 3 mois</label></div>
            </div>
            <div id="pieceCommuneError" class="error-text"></div>
        </div>

        <div id="piecesInvestisseur" class="form-section hidden">
            <h2>Pièces Investisseur</h2>
            <div class="checkbox-group">
                <div class="checkbox-item"><label><input type="checkbox" name="pieceInvestisseur" value="statutSociete"> Statut de la société</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceInvestisseur" value="registreCommerce"> Extrait d'inscription au registre du commerce</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceInvestisseur" value="carteFiscale"> Carte fiscale</label></div>
            </div>
            <div id="pieceInvestisseurError" class="error-text"></div>
        </div>

        <div id="piecesTravailleur" class="form-section hidden">
            <h2>Pièces Travailleur</h2>
            <div class="checkbox-group">
                <div class="checkbox-item"><label><input type="checkbox" name="pieceTravailleur" value="autorisationEmploi"> Autorisation d'emploi délivrée à Madagascar</label></div>
                <div class="checkbox-item"><label><input type="checkbox" name="pieceTravailleur" value="attestationEmployeur"> Attestation d'emploi originale</label></div>
            </div>
            <div id="pieceTravailleurError" class="error-text"></div>
        </div>

        <button type="submit" id="submitBtn" disabled>Soumettre</button>
    </form>
</div>

<script src="${pageContext.request.contextPath}/js/dynamicFields.js"></script>
<script src="${pageContext.request.contextPath}/js/validation.js"></script>
</body>
</html>
