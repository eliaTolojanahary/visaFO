function updateDynamicFields() {
    const profil = document.querySelector('input[name="profil"]:checked')?.value;
    const investisseurSection = document.getElementById('piecesInvestisseur');
    const travailleurSection = document.getElementById('piecesTravailleur');
    const investisseurItems = document.querySelectorAll('input[name="pieceInvestisseur"]');
    const travailleurItems = document.querySelectorAll('input[name="pieceTravailleur"]');

    if (profil === 'investisseur') {
        investisseurSection.classList.remove('hidden');
        travailleurSection.classList.add('hidden');
        investisseurItems.forEach(item => item.required = true);
        travailleurItems.forEach(item => item.required = false);
    } else if (profil === 'travailleur') {
        investisseurSection.classList.add('hidden');
        travailleurSection.classList.remove('hidden');
        investisseurItems.forEach(item => item.required = false);
        travailleurItems.forEach(item => item.required = true);
    } else {
        investisseurSection.classList.add('hidden');
        travailleurSection.classList.add('hidden');
        investisseurItems.forEach(item => item.required = false);
        travailleurItems.forEach(item => item.required = false);
    }

    validateForm();
}

function forceNouveauTitreOnly() {
    const type = document.getElementById('typeDemande');
    if (type && type.value !== 'Nouveau titre') {
        type.value = 'Nouveau titre';
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