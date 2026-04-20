/**
 * Gestion générale du formulaire
 * - Événements de soumission
 * - Gestion des réponses du serveur
 * - Messages de feedback utilisateur
 */

document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('demandeForm');
    
    if (!form) return;
    
    /**
     * Gère la soumission du formulaire
     */
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        // Valider avant d'envoyer
        if (!validateForm()) {
            return;
        }
        
        // Afficher un indicateur de chargement
        const submitBtn = document.getElementById('submitBtn');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Traitement en cours...';
        
        try {
            // Préparer les données du formulaire
            const formData = new FormData(form);
            
            // Envoyer le formulaire via fetch pour gestion d'erreur améliorée
            const response = await fetch(form.action, {
                method: 'POST',
                body: formData
            });
            
            if (response.ok) {
                // Afficher un message de succès
                showSuccessMessage('Votre demande a été enregistrée avec succès!');
                
                // Rediriger après 2 secondes
                setTimeout(() => {
                    window.location.href = '/visa/form?status=created';
                }, 2000);
            } else if (response.status === 400) {
                // Erreur de validation du serveur
                const errorData = await response.json().catch(() => ({}));
                showGlobalError(errorData.message || 'Erreur de validation. Veuillez vérifier vos données.');
            } else if (response.status === 422) {
                // Erreur métier (données incomplètes ou invalides)
                const errorData = await response.json().catch(() => ({}));
                showGlobalError(errorData.message || 'La demande ne peut pas être créée. Vérifiez tous les champs obligatoires.');
            } else {
                showGlobalError('Une erreur est survenue. Veuillez réessayer.');
            }
        } catch (error) {
            console.error('Erreur lors de la soumission:', error);
            showGlobalError('Erreur de connexion. Veuillez vérifier votre connexion Internet.');
        } finally {
            // Restaurer le bouton
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    });
    
    /**
     * Gère le bouton de réinitialisation
     */
    form.addEventListener('reset', function() {
        clearAllErrors();
        setTimeout(() => {
            updateDynamicFields();
            validateForm();
        }, 100);
    });
    
    /**
     * Gère la réaction au changement du type de demande
     */
    const typeDemande = document.getElementById('typeDemande');
    if (typeDemande) {
        typeDemande.addEventListener('change', updateFormDisplay);
    }
    
    /**
     * Gère les changements de profil
     */
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    profilRadios.forEach(radio => {
        radio.addEventListener('change', updateDynamicFields);
    });
});

/**
 * Affiche un message de succès
 */
function showSuccessMessage(message) {
    const globalError = document.getElementById('globalError');
    if (globalError) {
        globalError.innerHTML = `<span class="success-icon">✓</span> ${message}`;
        globalError.className = 'success-banner';
        globalError.style.display = 'block';
    }
}

/**
 * Affiche une erreur globale
 */
function showGlobalError(message) {
    const globalError = document.getElementById('globalError');
    if (globalError) {
        globalError.innerHTML = `<span class="error-icon">✕</span> ${message}`;
        globalError.className = 'error-banner';
        globalError.style.display = 'block';
        globalError.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

/**
 * Pré-remplit le formulaire si données en session (pour édition)
 */
function prefillFormData(data) {
    if (!data) return;
    
    // Remplir les champs principaux
    if (data.typeDemande) {
        document.getElementById('typeDemande').value = data.typeDemande;
    }
    
    if (data.profil) {
        const profilRadio = document.querySelector(`input[name="profil"][value="${data.profil}"]`);
        if (profilRadio) {
            profilRadio.checked = true;
            updateDynamicFields();
        }
    }
    
    // Remplir les champs d'état civil
    if (data.demandeur) {
        const demandeur = data.demandeur;
        if (demandeur.nom) document.getElementById('nom').value = demandeur.nom;
        if (demandeur.prenom) document.getElementById('prenom').value = demandeur.prenom;
        if (demandeur.nom_jeune_fille) document.getElementById('nomJeuneFille').value = demandeur.nom_jeune_fille;
        if (demandeur.date_naissance) document.getElementById('dateNaissance').value = demandeur.date_naissance;
        if (demandeur.lieu_naissance) document.getElementById('lieuNaissance').value = demandeur.lieu_naissance;
        if (demandeur.situationFamille) document.getElementById('situationFamille').value = demandeur.situationFamille;
        if (demandeur.nationalite) document.getElementById('nationalite').value = demandeur.nationalite;
        if (demandeur.adresseMadagascar) document.getElementById('adresseMadagascar').value = demandeur.adresseMadagascar;
        if (demandeur.numeroTelephone) document.getElementById('numeroTelephone').value = demandeur.numeroTelephone;
        if (demandeur.email) document.getElementById('email').value = demandeur.email;
        if (demandeur.profession) document.getElementById('profession').value = demandeur.profession;
    }
    
    // Remplir les champs de passeport
    if (data.passeport) {
        const passeport = data.passeport;
        if (passeport.numero) document.getElementById('passNumeroPas').value = passeport.numero;
        if (passeport.dateDelivrance) document.getElementById('passDateDelivrance').value = passeport.dateDelivrance;
        if (passeport.dateExpiration) document.getElementById('passDateExpiration').value = passeport.dateExpiration;
        if (passeport.lieuDelivrance) document.getElementById('passLieuDelivrance').value = passeport.lieuDelivrance;
    }
    
    // Remplir les champs de visa
    if (data.visa) {
        const visa = data.visa;
        if (visa.dateDelivrance) document.getElementById('visaDateEntree').value = visa.dateDelivrance;
        if (visa.dateExpiration) document.getElementById('visaDateExpiration').value = visa.dateExpiration;
    }
    
    // Cocher les pièces justificatives appropriées
    if (data.piecesJustificatives) {
        data.piecesJustificatives.forEach(piece => {
            const checkbox = document.querySelector(`input[value="${piece}"]`);
            if (checkbox) checkbox.checked = true;
        });
    }
    
    // Revalider le formulaire
    validateForm();
}

/**
 * Récupère les données du formulaire en objet JavaScript
 */
function getFormData() {
    const form = document.getElementById('demandeForm');
    const formData = new FormData(form);
    
    const data = {
        typeDemande: formData.get('typeDemande'),
        profil: document.querySelector('input[name="profil"]:checked')?.value,
        demandeur: {
            nom: formData.get('demandeur.nom'),
            prenom: formData.get('demandeur.prenom'),
            nom_jeune_fille: formData.get('demandeur.nom_jeune_fille'),
            date_naissance: formData.get('demandeur.date_naissance'),
            lieu_naissance: formData.get('demandeur.lieu_naissance'),
            situationFamille: formData.get('demandeur.situationFamille'),
            nationalite: formData.get('demandeur.nationalite'),
            adresseMadagascar: formData.get('demandeur.adresseMadagascar'),
            numeroTelephone: formData.get('demandeur.numeroTelephone'),
            email: formData.get('demandeur.email'),
            profession: formData.get('demandeur.profession')
        },
        passeport: {
            numero: formData.get('passeport.numero'),
            dateDelivrance: formData.get('passeport.dateDelivrance'),
            dateExpiration: formData.get('passeport.dateExpiration'),
            lieuDelivrance: formData.get('passeport.lieuDelivrance')
        },
        visa: {
            dateDelivrance: formData.get('visa.dateDelivrance'),
            dateExpiration: formData.get('visa.dateExpiration')
        },
        piecesCommunes: formData.getAll('pieceCommune'),
        piecesSpecifiques: formData.getAll('pieceInvestisseur').concat(formData.getAll('pieceTravailleur'))
    };
    
    return data;
}
