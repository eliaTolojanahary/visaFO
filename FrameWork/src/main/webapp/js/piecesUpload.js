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

    function findStatusNode(input) {
        var item = input.closest('.piece-item');
        return item ? item.querySelector('.piece-status') : null;
    }

    function resetStatus(input) {
        var status = findStatusNode(input);
        if (!status) return;

        var currentName = input.getAttribute('data-current-file-name') || '';
        if (currentName) {
            status.innerHTML = '<div class="file-info"><span class="icon icon-file"></span><strong>Fichier existant :</strong> ' + escapeHtml(currentName) + '</div>';
            return;
        }

        status.innerHTML = '<div class="no-file"><span class="icon icon-info"></span> Aucun fichier</div>';
    }

    function updateStatusForSelection(input) {
        var status = findStatusNode(input);
        if (!status) return;

        var file = input.files && input.files.length ? input.files[0] : null;
        if (!file) {
            resetStatus(input);
            return;
        }

        var error = validateFile(file);
        if (error) {
            status.innerHTML = '<div class="file-info error"><span class="icon icon-error"></span> ' + escapeHtml(error) + '</div>';
            input.value = '';
            return;
        }

        var sizeKb = (file.size / 1024).toFixed(1);
        status.innerHTML = '<div class="file-info success"><span class="icon icon-check"></span><strong>' + escapeHtml(file.name) + '</strong> (' + sizeKb + ' Ko)</div>';
    }

    function bindInputs() {
        var inputs = document.querySelectorAll('input.scan-piece-input[type="file"]');
        Array.prototype.forEach.call(inputs, function (input) {
            input.addEventListener('change', function () {
                updateStatusForSelection(input);
            });
            resetStatus(input);
        });
    }

    window.validatePieceUploads = function () {
        var valid = true;
        var inputs = document.querySelectorAll('input.scan-piece-input[type="file"]');
        var sectionErrors = {};

        Array.prototype.forEach.call(inputs, function (input) {
            var section = input.closest('.pieces-section');
            if (section && section.classList.contains('hidden')) {
                return;
            }

            var file = input.files && input.files.length ? input.files[0] : null;
            var hasExisting = input.getAttribute('data-current-file-name') && input.getAttribute('data-current-file-name').trim() !== '';
            var required = input.getAttribute('data-required') !== 'false';
            var sectionId = input.getAttribute('data-section-id') || '';
            var pieceTitle = '';
            var pieceItem = input.closest('.piece-item');
            if (pieceItem) {
                var titleNode = pieceItem.querySelector('.piece-title');
                if (titleNode) {
                    pieceTitle = (titleNode.textContent || '').trim();
                }
            }

            if (!file && (!hasExisting || required)) {
                valid = false;
                resetStatus(input);
                if (sectionId) {
                    if (!sectionErrors[sectionId]) {
                        sectionErrors[sectionId] = [];
                    }
                    sectionErrors[sectionId].push(pieceTitle || 'Pièce');
                }
                return;
            }

            if (file) {
                var error = validateFile(file);
                if (error) {
                    valid = false;
                    updateStatusForSelection(input);
                    if (sectionId) {
                        if (!sectionErrors[sectionId]) {
                            sectionErrors[sectionId] = [];
                        }
                        sectionErrors[sectionId].push((pieceTitle || 'Pièce') + ' (' + error + ')');
                    }
                }
            }
        });

        Object.keys(sectionErrors).forEach(function (sectionId) {
            var target = document.getElementById(sectionId);
            if (!target) return;
            target.innerHTML = '<ul class="error-list"><li>' + sectionErrors[sectionId].join('</li><li>') + '</li></ul>';
        });

        return valid;
    };

    window.addEventListener('DOMContentLoaded', bindInputs);
})();