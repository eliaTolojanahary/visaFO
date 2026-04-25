function updateDynamicFields() {
    const profil = document.querySelector('input[name="profil"]:checked')?.value;
    const investisseurSection = document.getElementById('piecesInvestisseur');
    const travailleurSection = document.getElementById('piecesTravailleur');
    const investisseurItems = investisseurSection
        ? investisseurSection.querySelectorAll('input[type="checkbox"][name="piece_ids"]')
        : [];
    const travailleurItems = travailleurSection
        ? travailleurSection.querySelectorAll('input[type="checkbox"][name="piece_ids"]')
        : [];

    if (profil === 'investisseur') {
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

    validateForm();
}

function getSelectedTypeDemandeLabel() {
    const type = document.getElementById('typeDemande');
    if (!type || !type.selectedOptions || !type.selectedOptions.length) return '';
    return (type.selectedOptions[0].textContent || '').trim().toLowerCase();
}

function updateDuplicataBlock() {
    const isDuplicata = getSelectedTypeDemandeLabel() === 'duplicata';
    const duplicataBlock = document.getElementById('duplicataBlock');
    const categorieDemande = document.getElementById('categorieDemande');
    const typeDocument = document.getElementById('typeDocument');

    if (duplicataBlock) {
        duplicataBlock.classList.toggle('hidden', !isDuplicata);
    }

    if (categorieDemande && isDuplicata) {
        categorieDemande.value = 'Duplicata';
    }

    if (typeDocument && isDuplicata && !typeDocument.value) {
        typeDocument.value = 'Titre de residence';
    }

    validateForm();
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
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    const typeDemandeInput = document.getElementById('typeDemande');

    profilRadios.forEach(radio => radio.addEventListener('change', updateDynamicFields));
    if (typeDemandeInput) {
        typeDemandeInput.addEventListener('change', function () {
            syncCategorieWithTypeDemande();
            updateDuplicataBlock();
        });
    }

    syncCategorieWithTypeDemande();
    updateDuplicataBlock();
    updateDynamicFields();
});