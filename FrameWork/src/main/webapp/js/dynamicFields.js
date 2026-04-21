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
        investisseurSection.classList.remove('hidden');
        travailleurSection.classList.add('hidden');
        travailleurItems.forEach(item => item.checked = false);
    } else if (profil === 'travailleur') {
        investisseurSection.classList.add('hidden');
        travailleurSection.classList.remove('hidden');
        investisseurItems.forEach(item => item.checked = false);
    } else {
        investisseurSection.classList.add('hidden');
        travailleurSection.classList.add('hidden');
        investisseurItems.forEach(item => item.checked = false);
        travailleurItems.forEach(item => item.checked = false);
    }

    validateForm();
}

function forceNouveauTitreOnly() {
    const type = document.getElementById('typeDemande');
    if (!type) return;

    const options = Array.from(type.options || []);
    const nouveauTitreOption = options.find(option =>
        option.textContent && option.textContent.trim().toLowerCase() === 'nouveau titre'
    );

    if (nouveauTitreOption) {
        type.value = nouveauTitreOption.value;
    }
}

window.addEventListener('DOMContentLoaded', function() {
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    const typeDemandeInput = document.getElementById('typeDemande');

    profilRadios.forEach(radio => radio.addEventListener('change', updateDynamicFields));
    if (typeDemandeInput) {
        typeDemandeInput.addEventListener('change', forceNouveauTitreOnly);
    }

    forceNouveauTitreOnly();
    updateDynamicFields();
});