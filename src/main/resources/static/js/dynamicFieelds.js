/**
 * Gestion des champs dynamiques selon le type de profil
 * - Investisseur: affiche les pièces justificatives investisseur
 * - Travailleur: affiche les pièces justificatives travailleur
 */

function updateDynamicFields() {
    const profilRadios = document.querySelectorAll('input[name="profil"]');
    const selectedProfil = Array.from(profilRadios).find(radio => radio.checked)?.value;
    
    const piecesInvestisseur = document.getElementById('piecesInvestisseur');
    const piecesTravailleur = document.getElementById('piecesTravailleur');
    
    // Réinitialiser les checkboxes spécifiques
    const investisseurCheckboxes = document.querySelectorAll('input[name="pieceInvestisseur"]');
    const travailleurCheckboxes = document.querySelectorAll('input[name="pieceTravailleur"]');
    
    investisseurCheckboxes.forEach(cb => cb.checked = false);
    travailleurCheckboxes.forEach(cb => cb.checked = false);
    
    // Afficher/masquer les sections appropriées
    if (selectedProfil === 'investisseur') {
        piecesInvestisseur.style.display = 'block';
        piecesTravailleur.style.display = 'none';
        
        // Définir les checkboxes investisseur comme requises
        investisseurCheckboxes.forEach(cb => cb.required = true);
        travailleurCheckboxes.forEach(cb => cb.required = false);
        
    } else if (selectedProfil === 'travailleur') {
        piecesInvestisseur.style.display = 'none';
        piecesTravailleur.style.display = 'block';
        
        // Définir les checkboxes travailleur comme requises
        investisseurCheckboxes.forEach(cb => cb.required = false);
        travailleurCheckboxes.forEach(cb => cb.required = true);
    } else {
        piecesInvestisseur.style.display = 'none';
        piecesTravailleur.style.display = 'none';
    }
    
    // Valider le formulaire
    validateForm();
}

/**
 * Gère l'affichage du formulaire en fonction du type de demande
 */
function updateFormDisplay() {
    const typeDemande = document.getElementById('typeDemande').value;
    
    // Pour cette première phase, seul "NOUVEAU" est actif
    if (typeDemande !== 'NOUVEAU') {
        alert('Cette option n\'est pas disponible pour le moment.');
        document.getElementById('typeDemande').value = 'NOUVEAU';
    }
}

/**
 * Initialisation au chargement de la page
 */
document.addEventListener('DOMContentLoaded', function() {
    // Initialiser l'affichage des champs dynamiques
    updateDynamicFields();
    
    // Ajouter les écouteurs d'événement pour la validation en temps réel
    const form = document.getElementById('demandeForm');
    const inputs = form.querySelectorAll('input, select, textarea');
    
    inputs.forEach(input => {
        input.addEventListener('change', validateForm);
        input.addEventListener('blur', validateForm);
    });
    
    // Valider au chargement
    validateForm();
});
