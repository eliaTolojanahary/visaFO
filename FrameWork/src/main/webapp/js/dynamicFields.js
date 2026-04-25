function isFieldFilled(fieldId) {
    const field = document.getElementById(fieldId);
    if (!field) return false;
    return field.value.trim() !== '';
}

function setSectionVisibility(sectionId, shouldShow) {
    const section = document.getElementById(sectionId);
    if (!section) return;
    section.classList.toggle('hidden', !shouldShow);
}

function isSectionVisible(sectionId) {
    const section = document.getElementById(sectionId);
    return !!section && !section.classList.contains('hidden');
}

function updateProgressiveFormSections() {
    const hasTypeDemande = isFieldFilled('typeDemande');
    const hasProfil = !!document.querySelector('input[name="profil"]:checked');
    const canShowEtatCivil = hasTypeDemande && hasProfil;

    const etatCivilRequiredFields = [
        'nom',
        'dateNaissance',
        'situationFamille',
        'nationalite',
        'adresseMadagascar',
        'numeroTelephone',
        'profession'
    ];
    const isEtatCivilComplete = etatCivilRequiredFields.every(isFieldFilled);

    const passeportRequiredFields = [
        'numeroPasseport',
        'dateDelivrance',
        'dateExpiration',
        'paysDelivrance'
    ];
    const isPasseportComplete = passeportRequiredFields.every(isFieldFilled);

    const visaRequiredFields = [
        'visaDateEntree',
        'visaLieuEntree',
        'visaDateExpiration',
        'categorieDemande'
    ];
    const isVisaComplete = visaRequiredFields.every(isFieldFilled);

    setSectionVisibility('sectionEtatCivil', canShowEtatCivil);
    setSectionVisibility('sectionPasseport', canShowEtatCivil && isEtatCivilComplete);
    setSectionVisibility('sectionVisa', canShowEtatCivil && isEtatCivilComplete && isPasseportComplete);
    setSectionVisibility('piecesCommunes', canShowEtatCivil && isEtatCivilComplete && isPasseportComplete && isVisaComplete);
}

function updateDynamicFields() {
    const profil = document.querySelector('input[name="profil"]:checked')?.value;
    const investisseurSection = document.getElementById('piecesInvestisseur');
    const travailleurSection = document.getElementById('piecesTravailleur');
    const canShowProfilePieces = isSectionVisible('piecesCommunes');
    const investisseurItems = investisseurSection
        ? investisseurSection.querySelectorAll('input[type="checkbox"][name="piece_ids"]')
        : [];
    const travailleurItems = travailleurSection
        ? travailleurSection.querySelectorAll('input[type="checkbox"][name="piece_ids"]')
        : [];

    if (!canShowProfilePieces) {
        if (investisseurSection) investisseurSection.classList.add('hidden');
        if (travailleurSection) travailleurSection.classList.add('hidden');
    } else if (profil === 'investisseur') {
        if (investisseurSection) investisseurSection.classList.remove('hidden');
        if (travailleurSection) travailleurSection.classList.add('hidden');
        travailleurItems.forEach(item => item.checked = false);
    } else if (profil === 'travailleur') {
        if (investisseurSection) investisseurSection.classList.add('hidden');
        if (travailleurSection) travailleurSection.classList.remove('hidden');
        investisseurItems.forEach(item => item.checked = false);
    } else {
        if (investisseurSection) investisseurSection.classList.add('hidden');
        if (travailleurSection) travailleurSection.classList.add('hidden');
        investisseurItems.forEach(item => item.checked = false);
        travailleurItems.forEach(item => item.checked = false);
    }

    syncAllSelectAllStates();
    validateForm();
}

function getPieceCheckboxes(sectionElement) {
    if (!sectionElement) return [];
    return Array.from(sectionElement.querySelectorAll('input[type="checkbox"][name="piece_ids"]'));
}

function updateSelectAllState(targetSectionId) {
    const section = document.getElementById(targetSectionId);
    const selectAll = document.querySelector('.js-select-all-pieces[data-target-section="' + targetSectionId + '"]');
    if (!section || !selectAll) return;

    const checkboxes = getPieceCheckboxes(section);
    if (!checkboxes.length) {
        selectAll.checked = false;
        selectAll.indeterminate = false;
        return;
    }

    const checkedCount = checkboxes.filter(input => input.checked).length;
    selectAll.checked = checkedCount > 0 && checkedCount === checkboxes.length;
    selectAll.indeterminate = checkedCount > 0 && checkedCount < checkboxes.length;
}

function syncAllSelectAllStates() {
    const selectAllInputs = document.querySelectorAll('.js-select-all-pieces[data-target-section]');
    selectAllInputs.forEach(input => {
        const targetSectionId = input.dataset.targetSection;
        if (targetSectionId) updateSelectAllState(targetSectionId);
    });
}

function initializeSelectAllPieces() {
    const selectAllInputs = document.querySelectorAll('.js-select-all-pieces[data-target-section]');
    selectAllInputs.forEach(selectAllInput => {
        const targetSectionId = selectAllInput.dataset.targetSection;
        const targetSection = targetSectionId ? document.getElementById(targetSectionId) : null;
        if (!targetSection) return;

        const pieceCheckboxes = getPieceCheckboxes(targetSection);

        selectAllInput.addEventListener('change', function () {
            pieceCheckboxes.forEach(checkbox => {
                checkbox.checked = selectAllInput.checked;
            });
            updateSelectAllState(targetSectionId);
            validateForm();
        });

        pieceCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', function () {
                updateSelectAllState(targetSectionId);
            });
        });

        updateSelectAllState(targetSectionId);
    });
}

function getSelectedTypeDemandeLabel() {
    const type = document.getElementById('typeDemande');
    if (!type || !type.selectedOptions || !type.selectedOptions.length) return '';
    return (type.selectedOptions[0].textContent || '').trim().toLowerCase();
}

function updateDuplicataBlock() {
    const isDuplicata = getSelectedTypeDemandeLabel() === 'duplicata';
    const canShowDuplicata = isSectionVisible('sectionVisa');
    const duplicataBlock = document.getElementById('duplicataBlock');
    const categorieDemande = document.getElementById('categorieDemande');
    const typeDocument = document.getElementById('typeDocument');

    if (duplicataBlock) {
        duplicataBlock.classList.toggle('hidden', !(isDuplicata && canShowDuplicata));
    }

    if (categorieDemande && isDuplicata) {
        categorieDemande.value = 'Duplicata';
    }

    if (typeDocument && isDuplicata && !typeDocument.value) {
        typeDocument.value = 'Titre de residence';
    }

}

function refreshDynamicLayout() {
    updateProgressiveFormSections();
    updateDuplicataBlock();
    updateDynamicFields();
}

function syncCategorieWithTypeDemande() {
    const type = document.getElementById('typeDemande');
    const categorieDemande = document.getElementById('categorieDemande');
    if (!type || !categorieDemande || !type.selectedOptions || !type.selectedOptions.length) return;

    const selectedLabel = (type.selectedOptions[0].textContent || '').trim();
    if (selectedLabel) {
        categorieDemande.value = selectedLabel;
    }
}

window.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('demandeForm');
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    const typeDemandeInput = document.getElementById('typeDemande');

    initializeSelectAllPieces();

    profilRadios.forEach(radio => radio.addEventListener('change', refreshDynamicLayout));
    if (typeDemandeInput) {
        typeDemandeInput.addEventListener('change', function () {
            syncCategorieWithTypeDemande();
            refreshDynamicLayout();
        });
    }

    if (form) {
        form.addEventListener('input', refreshDynamicLayout);
        form.addEventListener('change', refreshDynamicLayout);
    }

    syncCategorieWithTypeDemande();
    refreshDynamicLayout();
});