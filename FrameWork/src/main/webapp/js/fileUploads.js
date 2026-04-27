/**
 * fileUploads.js - Gestion dynamique des uploads de pièces justificatives
 * Affiche/masque les champs de fichier en fonction de la sélection des pièces justificatives
 * Structure simplifiée basée sur scanDemande.jsp
 */

(function () {
    'use strict';

    /**
     * Mettre à jour les champs d'upload en fonction des pièces sélectionnées
     */
    function updateUploadFields() {
        const uploadsSection = document.getElementById('uploadsSection');
        const container = document.getElementById('piecesUploadContainer');
        
        if (!uploadsSection || !container) return;

        // Récupérer les pièces cochées avec leurs labels
        const checkedPieces = Array.from(document.querySelectorAll('input[name="piece_ids"]:checked'))
            .map(cb => {
                const label = cb.closest('.checkbox-item')
                    ? (cb.closest('.checkbox-item').querySelector('label')?.textContent || '').replace(/\s*\*/g, '').trim()
                    : `Pièce ${cb.value}`;
                return {
                    id: cb.value,
                    label: label
                };
            });

        // Vider le conteneur
        container.innerHTML = '';

        if (checkedPieces.length === 0) {
            // Masquer la section si aucune pièce n'est sélectionnée
            uploadsSection.classList.add('hidden');
            return;
        }

        // Afficher la section
        uploadsSection.classList.remove('hidden');

        // Créer les champs d'upload pour chaque pièce sélectionnée
        checkedPieces.forEach(piece => {
            const pieceItem = createPieceUploadItem(piece.id, piece.label);
            container.appendChild(pieceItem);
        });
    }

    /**
     * Créer un élément piece-item pour l'upload (structure de scanDemande.jsp)
     * @param {string} pieceId - ID de la pièce
     * @param {string} pieceLabel - Libellé de la pièce
     * @returns {HTMLElement} Div piece-item
     */
    function createPieceUploadItem(pieceId, pieceLabel) {
        const pieceItem = document.createElement('div');
        pieceItem.className = 'piece-item';
        pieceItem.dataset.pieceId = pieceId;

        const pieceTitle = document.createElement('div');
        pieceTitle.className = 'piece-title';
        pieceTitle.textContent = escapeHtml(pieceLabel);

        const uploadForm = document.createElement('form');
        uploadForm.className = 'upload-form';
        uploadForm.enctype = 'multipart/form-data';
        uploadForm.method = 'post';
        uploadForm.noValidate = true;

        const formGroup = document.createElement('div');
        formGroup.className = 'form-group';

        const label = document.createElement('label');
        label.setAttribute('for', `file_${pieceId}`);
        label.textContent = 'Sélectionner un fichier (JPEG, PNG, PDF - Max 10 Mo)';

        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.id = `file_${pieceId}`;
        fileInput.name = `piece_file_${pieceId}`;
        fileInput.accept = 'image/jpeg,image/png,application/pdf';
        fileInput.className = 'piece-file-input';
        fileInput.dataset.pieceId = pieceId;
        fileInput.addEventListener('change', handleFileChange);

        const fileStatus = document.createElement('div');
        fileStatus.className = 'file-status';
        fileStatus.id = `status_${pieceId}`;

        const submitBtn = document.createElement('button');
        submitBtn.type = 'submit';
        submitBtn.className = 'btn-upload';
        submitBtn.textContent = 'Uploader cette pièce';
        submitBtn.disabled = true;
        submitBtn.style.display = 'none';

        formGroup.appendChild(label);
        formGroup.appendChild(fileInput);
        formGroup.appendChild(fileStatus);

        uploadForm.appendChild(formGroup);
        uploadForm.appendChild(submitBtn);

        pieceItem.appendChild(pieceTitle);
        pieceItem.appendChild(uploadForm);

        return pieceItem;
    }

    /**
     * Gérer la sélection d'un fichier
     */
    function handleFileChange(event) {
        const input = event.target;
        const pieceId = input.dataset.pieceId;
        const statusEl = document.getElementById(`status_${pieceId}`);
        const file = input.files[0];

        if (!statusEl) return;

        // Réinitialiser le statut
        statusEl.innerHTML = '';
        statusEl.className = 'file-status';

        if (!file) {
            return;
        }

        // Valider le type
        if (!validateFileType(file)) {
            statusEl.className = 'file-status file-status--error';
            statusEl.innerHTML = '<span class="icon icon-error"></span> Format non accepté. Utilisez JPEG, PNG ou PDF.';
            input.value = '';
            return;
        }

        // Valider la taille
        if (!validateFileSize(file)) {
            statusEl.className = 'file-status file-status--error';
            statusEl.innerHTML = '<span class="icon icon-error"></span> Fichier trop volumineux (max 10 Mo).';
            input.value = '';
            return;
        }

        // Afficher le succès
        const sizeKb = (file.size / 1024).toFixed(1);
        statusEl.className = 'file-status file-status--success';
        statusEl.innerHTML = `<span class="icon icon-check"></span> ${escapeHtml(file.name)} (${sizeKb} Ko)`;
    }

    /**
     * Valider la taille d'un fichier (10 Mo max)
     */
    function validateFileSize(file) {
        const maxSize = 10 * 1024 * 1024; // 10 Mo
        return file.size <= maxSize;
    }

    /**
     * Valider le type MIME d'un fichier
     */
    function validateFileType(file) {
        const validTypes = ['image/jpeg', 'image/png', 'application/pdf'];
        return validTypes.includes(file.type);
    }

    /**
     * Échapper les caractères HTML
     */
    function escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    /**
     * Valider que tous les fichiers des pièces cochées sont fournis
     */
    window.validateRequiredFiles = function() {
        const errors = [];
        const uploadsSection = document.getElementById('uploadsSection');
        
        // Si la section n'est pas affichée, pas de fichiers requis
        if (!uploadsSection || uploadsSection.classList.contains('hidden')) {
            return true;
        }

        const checkedPieces = document.querySelectorAll('input[name="piece_ids"]:checked');
        
        checkedPieces.forEach(checkbox => {
            const pieceId = checkbox.value;
            const fileInput = document.querySelector(`input[name="piece_file_${pieceId}"]`);
            const label = checkbox.closest('.checkbox-item')
                ? (checkbox.closest('.checkbox-item').querySelector('label')?.textContent || '').replace(/\s*\*/g, '').trim()
                : `Pièce ${pieceId}`;
            
            if (!fileInput || !fileInput.value) {
                errors.push(`Le fichier pour "${label}" est obligatoire.`);
            }
        });

        if (errors.length > 0) {
            const errorContainer = document.getElementById('piecesUploadError');
            if (errorContainer) {
                errorContainer.innerHTML = '<ul class="error-list">' 
                    + errors.map(err => `<li>${err}</li>`).join('') 
                    + '</ul>';
                errorContainer.className = 'error-text';
            }
            return false;
        }

        // Réinitialiser les erreurs
        const errorContainer = document.getElementById('piecesUploadError');
        if (errorContainer) {
            errorContainer.innerHTML = '';
        }
        return true;
    };

    /**
     * Initialiser le module
     */
    function init() {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initEventListeners);
        } else {
            initEventListeners();
        }
    }

    /**
     * Initialiser les écouteurs d'événements
     */
    function initEventListeners() {
        // Écouteurs pour les changements de checkboxes des pièces
        const pieceCheckboxes = document.querySelectorAll('input[name="piece_ids"]');
        pieceCheckboxes.forEach(checkbox => {
            checkbox.addEventListener('change', updateUploadFields);
        });

        // Initiale mise à jour
        updateUploadFields();
    }

    // Lancer l'initialisation
    init();
})();
