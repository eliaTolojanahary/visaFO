(function () {
    'use strict';

    var ACCEPTED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    var MAX_BYTES = 10 * 1024 * 1024;

    function escapeHtml(value) {
        var div = document.createElement('div');
        div.textContent = String(value == null ? '' : value);
        return div.innerHTML;
    }

    function validateFile(file) {
        if (ACCEPTED_TYPES.indexOf(file.type) === -1) {
            return 'Format non accepté. Utilisez PDF, JPG ou PNG.';
        }
        if (file.size > MAX_BYTES) {
            return 'Fichier trop volumineux (max 10 Mo).';
        }
        return '';
    }

    function getCheckedCheckboxes() {
        return Array.prototype.slice.call(document.querySelectorAll('.js-piece-checkbox:checked'));
    }

    function getPieceLabel(pieceId) {
        var label = document.querySelector('label[for="check-' + pieceId + '"] .piece-card__label');
        return label ? (label.textContent || '').trim() : ('Pièce ' + pieceId);
    }

    function updateStatusForSelection(input) {
        if (!input) return;
        var pieceId = input.getAttribute('data-piece-id');
        var status = document.getElementById('status-' + pieceId);
        var chosen = document.getElementById('chosen-' + pieceId);
        if (!status) return;

        var file = input.files && input.files.length ? input.files[0] : null;
        status.innerHTML = '';
        status.className = 'piece-status';

        if (!file) {
            if (chosen) chosen.textContent = 'Aucun fichier choisi';
            status.innerHTML = '<div class="no-file"><span class="icon icon-info"></span> Aucun fichier</div>';
            return;
        }

        var error = validateFile(file);
        if (error) {
            status.innerHTML = '<div class="file-info error"><span class="icon icon-error"></span> ' + escapeHtml(error) + '</div>';
            input.value = '';
            if (chosen) chosen.textContent = 'Aucun fichier choisi';
            return;
        }

        var sizeKb = (file.size / 1024).toFixed(1);
        if (chosen) chosen.textContent = file.name;
        status.innerHTML = '<div class="file-info success"><span class="icon icon-check"></span><strong>' + escapeHtml(file.name) + '</strong> (' + sizeKb + ' Ko)</div>';
    }

    function syncInlineUploadVisibility() {
        var checkboxes = document.querySelectorAll('.js-piece-checkbox');
        Array.prototype.forEach.call(checkboxes, function (checkbox) {
            var pieceId = checkbox.value;
            var uploadBlock = document.getElementById('form-' + pieceId);
            if (!uploadBlock) return;
            uploadBlock.style.display = checkbox.checked ? '' : 'none';
        });
    }

    function bindInlineInputs() {
        var inputs = document.querySelectorAll('input.scan-piece-input[type="file"]');
        Array.prototype.forEach.call(inputs, function (input) {
            if (input.dataset.boundUpload === '1') return;
            input.dataset.boundUpload = '1';
            input.addEventListener('change', function () {
                updateStatusForSelection(input);
            });
        });
    }

    window.validatePieceUploads = function () {
        var valid = true;
        var errors = [];
        var errorContainer = document.getElementById('piecesUploadError');

        getCheckedCheckboxes().forEach(function (checkbox) {
            var pieceId = checkbox.value;
            var input = document.getElementById('file-input-' + pieceId);
            var file = input && input.files && input.files.length ? input.files[0] : null;
            var label = getPieceLabel(pieceId);

            if (!file) {
                valid = false;
                errors.push('Le fichier pour "' + escapeHtml(label) + '" est obligatoire.');
                return;
            }

            var error = validateFile(file);
            if (error) {
                valid = false;
                errors.push('"' + escapeHtml(label) + '": ' + escapeHtml(error));
            }
        });

        if (!errorContainer) {
            return valid;
        }

        if (!valid) {
            errorContainer.innerHTML = '<ul class="error-list"><li>' + errors.join('</li><li>') + '</li></ul>';
            return false;
        }

        errorContainer.innerHTML = '';
        return true;
    };

    function onPiecesRendered() {
        bindInlineInputs();
        syncInlineUploadVisibility();
    }

    function initEventListeners() {
        document.addEventListener('change', function (event) {
            if (event.target && event.target.classList && event.target.classList.contains('js-piece-checkbox')) {
                syncInlineUploadVisibility();
            }
        });

        document.addEventListener('pieces:updated', onPiecesRendered);
        onPiecesRendered();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initEventListeners);
    } else {
        initEventListeners();
    }
})();