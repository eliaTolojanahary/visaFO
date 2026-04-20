/**
 * Validation du formulaire de demande de visa
 * Vérifie tous les champs obligatoires et affiche les erreurs
 */

/**
 * Validation complète du formulaire
 */
function validateForm() {
    const form = document.getElementById('demandeForm');
    const errors = [];
    
    // Réinitialiser les messages d'erreur
    clearAllErrors();
    
    // Valider Type de Demande
    const typeDemande = document.getElementById('typeDemande').value;
    if (!typeDemande) {
        errors.push('type_demande');
        showError('typeDemandeError', 'Veuillez sélectionner un type de demande');
    }
    
    // Valider Profil
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    const profilSelected = Array.from(profilRadios).some(radio => radio.checked);
    if (!profilSelected) {
        errors.push('profil');
        showError('profilError', 'Veuillez sélectionner un profil');
    }
    
    // Valider Etat Civil
    const nom = document.getElementById('nom').value.trim();
    if (!nom) {
        errors.push('nom');
        showError('nomError', 'Le nom est obligatoire');
    }
    
    const nomJeuneFille = document.getElementById('nomJeuneFille').value.trim();
    if (!nomJeuneFille) {
        errors.push('nomJeuneFille');
        showError('nomJeuneFilleError', 'Le nom de jeune fille est obligatoire');
    }
    
    const dateNaissance = document.getElementById('dateNaissance').value;
    if (!dateNaissance) {
        errors.push('dateNaissance');
        showError('dateNaissanceError', 'La date de naissance est obligatoire');
    }
    
    const situationFamille = document.getElementById('situationFamille').value;
    if (!situationFamille) {
        errors.push('situationFamille');
        showError('situationFamilleError', 'La situation de famille est obligatoire');
    }
    
    const nationalite = document.getElementById('nationalite').value;
    if (!nationalite) {
        errors.push('nationalite');
        showError('nationaliteError', 'La nationalité est obligatoire');
    }
    
    const adresseMadagascar = document.getElementById('adresseMadagascar').value.trim();
    if (!adresseMadagascar) {
        errors.push('adresseMadagascar');
        showError('adresseMadagascarError', 'L\'adresse à Madagascar est obligatoire');
    }
    
    const numeroTelephone = document.getElementById('numeroTelephone').value.trim();
    if (!numeroTelephone) {
        errors.push('numeroTelephone');
        showError('numeroTelephoneError', 'Le numéro de téléphone est obligatoire');
    } else if (!isValidPhone(numeroTelephone)) {
        errors.push('numeroTelephone');
        showError('numeroTelephoneError', 'Le format du numéro de téléphone est invalide');
    }
    
    const profession = document.getElementById('profession').value.trim();
    if (!profession) {
        errors.push('profession');
        showError('professionError', 'La profession est obligatoire');
    }
    
    // Valider Email (optionnel, mais si rempli, doit être valide)
    const email = document.getElementById('email').value.trim();
    if (email && !isValidEmail(email)) {
        errors.push('email');
        showError('emailError', 'Le format de l\'email est invalide');
    }
    
    // Valider Passeport
    const passNumero = document.getElementById('passNumeroPas').value.trim();
    if (!passNumero) {
        errors.push('passNumero');
        showError('passNumeroError', 'Le numéro de passeport est obligatoire');
    }
    
    const passDateDelivrance = document.getElementById('passDateDelivrance').value;
    if (!passDateDelivrance) {
        errors.push('passDateDelivrance');
        showError('passDateDelivranceError', 'La date de délivrance est obligatoire');
    }
    
    const passDateExpiration = document.getElementById('passDateExpiration').value;
    if (!passDateExpiration) {
        errors.push('passDateExpiration');
        showError('passDateExpirationError', 'La date d\'expiration est obligatoire');
    } else if (!isDateValid(passDateExpiration)) {
        errors.push('passDateExpiration');
        showError('passDateExpirationError', 'Le passeport est expiré');
    }
    
    const passLieuDelivrance = document.getElementById('passLieuDelivrance').value.trim();
    if (!passLieuDelivrance) {
        errors.push('passLieuDelivrance');
        showError('passLieuDelivranceError', 'Le pays de délivrance est obligatoire');
    }
    
    // Valider Visa
    const visaDateEntree = document.getElementById('visaDateEntree').value;
    if (!visaDateEntree) {
        errors.push('visaDateEntree');
        showError('visaDateEntreeError', 'La date d\'entrée est obligatoire');
    }
    
    const visaLieuEntree = document.querySelector('input[id="visaLieuEntree"]').value.trim();
    if (!visaLieuEntree) {
        errors.push('visaLieuEntree');
        showError('visaLieuEntreeError', 'Le lieu d\'entrée est obligatoire');
    }
    
    const visaDateExpiration = document.getElementById('visaDateExpiration').value;
    if (!visaDateExpiration) {
        errors.push('visaDateExpiration');
        showError('visaDateExpirationError', 'La date d\'expiration du visa est obligatoire');
    } else if (!isDateValid(visaDateExpiration)) {
        errors.push('visaDateExpiration');
        showError('visaDateExpirationError', 'Le visa est expiré');
    }
    
    const visaCategorie = document.querySelector('input[id="visaCategorie"]').value.trim();
    if (!visaCategorie) {
        errors.push('visaCategorie');
        showError('visaCategorieError', 'La catégorie de demande est obligatoire');
    }
    
    // Valider Pièces Communes
    const piecesCommunes = document.querySelectorAll('input[name="pieceCommune"]');
    const pieceCommuneChecked = Array.from(piecesCommunes).some(cb => cb.checked);
    if (!pieceCommuneChecked) {
        errors.push('pieceCommune');
        showError('pieceCommuneError', 'Veuillez sélectionner au moins une pièce commune');
    }
    
    // Valider Pièces Spécifiques selon le profil
    const selectedProfil = Array.from(profilRadios).find(radio => radio.checked)?.value;
    
    if (selectedProfil === 'investisseur') {
        const piecesInvestisseur = document.querySelectorAll('input[name="pieceInvestisseur"]');
        const pieceInvestisseurChecked = Array.from(piecesInvestisseur).some(cb => cb.checked);
        if (!pieceInvestisseurChecked) {
            errors.push('pieceInvestisseur');
            showError('pieceInvestisseurError', 'Veuillez sélectionner au moins une pièce investisseur');
        }
    } else if (selectedProfil === 'travailleur') {
        const piecesTravailleur = document.querySelectorAll('input[name="pieceTravailleur"]');
        const pieceTravailleurChecked = Array.from(piecesTravailleur).some(cb => cb.checked);
        if (!pieceTravailleurChecked) {
            errors.push('pieceTravailleur');
            showError('pieceTravailleurError', 'Veuillez sélectionner au moins une pièce travailleur');
        }
    }
    
    // Activer/désactiver le bouton de soumission
    const submitBtn = document.getElementById('submitBtn');
    if (errors.length === 0) {
        submitBtn.disabled = false;
        submitBtn.classList.add('btn-enabled');
        submitBtn.classList.remove('btn-disabled');
    } else {
        submitBtn.disabled = true;
        submitBtn.classList.remove('btn-enabled');
        submitBtn.classList.add('btn-disabled');
    }
    
    return errors.length === 0;
}

/**
 * Affiche un message d'erreur
 */
function showError(elementId, message) {
    const errorElement = document.getElementById(elementId);
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

/**
 * Efface tous les messages d'erreur
 */
function clearAllErrors() {
    const errorMessages = document.querySelectorAll('.error-message');
    errorMessages.forEach(msg => {
        msg.textContent = '';
        msg.style.display = 'none';
    });
}

/**
 * Valide le format d'une adresse email
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Valide le format d'un numéro de téléphone Madagascar
 */
function isValidPhone(phone) {
    // Accepte format: +261XXXXXXXXX ou +261 XX XXX XXXX ou 0XXXXXXXXX
    const phoneRegex = /^(\+261|0)[2-8]\d{8}$|^(\+261|0)[2-8]\d{2}\s\d{3}\s\d{4}$/;
    return phoneRegex.test(phone.replace(/\s/g, ''));
}

/**
 * Vérifie si une date est dans le futur (pas expirée)
 */
function isDateValid(dateString) {
    const date = new Date(dateString);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return date >= today;
}

/**
 * Validation lors de la soumission du formulaire
 */
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('demandeForm');
    
    if (form) {
        form.addEventListener('submit', function(e) {
            if (!validateForm()) {
                e.preventDefault();
                const globalError = document.getElementById('globalError');
                globalError.textContent = '⚠️ Veuillez corriger tous les erreurs avant de soumettre.';
                globalError.style.display = 'block';
                
                // Scroll jusqu'au premier erreur
                const firstError = document.querySelector('.error-message:not(:empty)');
                if (firstError) {
                    firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }
        });
    }
});
