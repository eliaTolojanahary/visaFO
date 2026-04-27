function showError(id, message) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = message;
    el.style.display = 'block';
}

function getSelectedTypeDemandeLabel() {
    const type = document.getElementById('typeDemande');
    if (!type || !type.selectedOptions || !type.selectedOptions.length) return '';
    return (type.selectedOptions[0].textContent || '').trim().toLowerCase();
}

function isDuplicataSelected() {
    return getSelectedTypeDemandeLabel() === 'duplicata';
}

function getCheckedCountInSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (!section) return 0;
    return section.querySelectorAll('input[type="checkbox"][name="piece_ids"]:checked').length;
}

function getTotalCountInSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (!section) return 0;
    return section.querySelectorAll('input[type="checkbox"][name="piece_ids"]').length;
}

function hasAtLeastOneChecked(sectionId) {
    return getCheckedCountInSection(sectionId) > 0;
}

function clearErrors() {
    document.querySelectorAll('.error-text').forEach(el => {
        el.textContent = '';
        el.style.display = 'none';
    });
    const banner = document.getElementById('globalMessage');
    if (banner) {
        banner.textContent = '';
        banner.className = '';
        banner.style.display = 'none';
    }
}

function showGlobalValidationMessage(message) {
    const banner = document.getElementById('globalMessage');
    if (!banner) return;
    banner.textContent = message;
    banner.className = 'error-banner';
    banner.style.display = 'block';
}

function validateForm() {
    clearErrors();
    let valid = true;

    const requiredIds = [
        'typeDemande',
        'nom',
        'nomJeuneFille',
        'dateNaissance',
        'situationFamille',
        'nationalite',
        'adresseMadagascar',
        'numeroTelephone',
        'profession',
        'numeroPasseport',
        'dateDelivrance',
        'dateExpiration',
        'paysDelivrance',
        'visaDateEntree',
        'visaLieuEntree',
        'visaDateExpiration',
        'categorieDemande'
    ];

    requiredIds.forEach(id => {
        const field = document.getElementById(id);
        if (!field || !field.value.trim()) {
            valid = false;
            showError(id + 'Error', 'Ce champ est obligatoire');
        }
    });

    const profil = document.querySelector('input[name="profil"]:checked');
    if (!profil) {
        valid = false;
        showError('profilError', 'Le profil est obligatoire');
    }

    const duplicataMode = isDuplicataSelected();

    const piecesCommunesTotal = getTotalCountInSection('piecesCommunes');
    const checkedCommunes = getCheckedCountInSection('piecesCommunes');

    if (!duplicataMode && piecesCommunesTotal > 0 && checkedCommunes === 0) {
        valid = false;
        showError('pieceCommuneError', 'Veuillez cocher au moins une piece commune');
    }

    if (profil) {
        if (profil.value === 'investisseur') {
            const piecesInvestisseurTotal = getTotalCountInSection('piecesInvestisseur');
            const checkedInvestisseur = getCheckedCountInSection('piecesInvestisseur');
            if (!duplicataMode && piecesInvestisseurTotal > 0 && checkedInvestisseur === 0) {
                valid = false;
                showError('pieceInvestisseurError', 'Veuillez cocher au moins une piece investisseur');
            }
        }
        if (profil.value === 'travailleur') {
            const piecesTravailleurTotal = getTotalCountInSection('piecesTravailleur');
            const checkedTravailleur = getCheckedCountInSection('piecesTravailleur');
            if (!duplicataMode && piecesTravailleurTotal > 0 && checkedTravailleur === 0) {
                valid = false;
                showError('pieceTravailleurError', 'Veuillez cocher au moins une piece travailleur');
            }
        }
    }

    if (duplicataMode) {
        const visaApprouve = document.getElementById('visaApprouveConfirme');
        const typeDocument = document.getElementById('typeDocument');
        const checkedTotal = checkedCommunes
            + getCheckedCountInSection('piecesInvestisseur')
            + getCheckedCountInSection('piecesTravailleur');

        if (!visaApprouve || !visaApprouve.checked) {
            valid = false;
            showError('visaApprouveConfirmeError', 'La confirmation du visa approuve est obligatoire');
        }

        if (!typeDocument || !typeDocument.value || typeDocument.value.trim().toLowerCase() !== 'titre de residence') {
            valid = false;
            showError('typeDocumentError', 'Le type de document doit etre Titre de residence');
        }

        if (checkedTotal < 1) {
            valid = false;
            showError('duplicataPieceError', 'Au moins une piece justificative doit etre cochee pour le duplicata');
        }
    }

    const reviewBtn = document.getElementById('reviewBtn');
    if (reviewBtn) {
        reviewBtn.disabled = !valid;
    }

    const submitBtn = document.getElementById('submitBtn');
    if (submitBtn) {
        submitBtn.disabled = !valid;
    }

    if (!valid && window.__reviewAttempted) {
        showGlobalValidationMessage('Le formulaire contient des erreurs. Corrigez les champs en rouge avant de continuer.');
    }

    return valid;
}

window.addEventListener('DOMContentLoaded', function () {
    const inputs = document.querySelectorAll('input, select, textarea');
    inputs.forEach(el => {
        el.addEventListener('input', validateForm);
        el.addEventListener('change', validateForm);
    });

    validateForm();
});