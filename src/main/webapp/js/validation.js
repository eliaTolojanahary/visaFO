function showError(id, message) {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = message;
    el.style.display = 'block';
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

function validateForm() {
    clearErrors();
    let valid = true;

    const requiredIds = [
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

    const piecesCommunes = document.querySelectorAll('input[name="pieceCommune"]:checked');
    if (piecesCommunes.length === 0) {
        valid = false;
        showError('pieceCommuneError', 'Veuillez cocher au moins une pièce commune');
    }

    if (profil) {
        if (profil.value === 'investisseur') {
            const piecesInvestisseur = document.querySelectorAll('input[name="pieceInvestisseur"]:checked');
            if (piecesInvestisseur.length === 0) {
                valid = false;
                showError('pieceInvestisseurError', 'Veuillez cocher au moins une pièce investisseur');
            }
        }
        if (profil.value === 'travailleur') {
            const piecesTravailleur = document.querySelectorAll('input[name="pieceTravailleur"]:checked');
            if (piecesTravailleur.length === 0) {
                valid = false;
                showError('pieceTravailleurError', 'Veuillez cocher au moins une pièce travailleur');
            }
        }
    }

    const submitBtn = document.getElementById('submitBtn');
    if (submitBtn) {
        submitBtn.disabled = !valid;
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