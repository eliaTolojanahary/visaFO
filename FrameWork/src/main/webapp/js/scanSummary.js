/*
 * scanSummary.js
 * Synchronise le résumé du scan avec le statut métier serveur.
 */
(function () {
    'use strict';

    function getAppRoot() {
        var segments = window.location.pathname.split('/');
        return segments.length > 1 ? segments[1] : '';
    }

    function getSummarySection() {
        return document.getElementById('scanSummarySection');
    }

    function getDemandeId() {
        var section = getSummarySection();
        if (section && section.dataset.demandeId) {
            return section.dataset.demandeId;
        }

        var photoBlock = document.getElementById('photo-identite-block');
        if (photoBlock && photoBlock.dataset.demandeId) {
            return photoBlock.dataset.demandeId;
        }

        var signatureBloc = document.getElementById('signatureBloc');
        if (signatureBloc && signatureBloc.dataset.demandeId) {
            return signatureBloc.dataset.demandeId;
        }

        return '';
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function renderPieceList(pieces) {
        var container = document.getElementById('scanPiecesSummary');
        if (!container) {
            return;
        }

        if (!pieces || !pieces.length) {
            container.innerHTML = '<div class="hint-text">Aucune piece a afficher pour le moment.</div>';
            return;
        }

        var html = ['<ul class="scan-summary-list">'];
        pieces.forEach(function (piece) {
            var status = String(piece && piece.scanStatut ? piece.scanStatut : 'EN_ATTENTE');
            var uploaded = status === 'SCANNÉ' || status === 'SCANNED';
            var fileName = piece && piece.fileName ? piece.fileName : '';
            var uploadedAt = piece && piece.uploadedAt ? piece.uploadedAt : '';
            var pieceLabel = piece && piece.pieceLibelle ? piece.pieceLibelle : 'Piece';
            var special = !!(piece && piece.special);

            html.push('<li class="scan-summary-row ' + (uploaded ? 'scan-summary-row--done' : 'scan-summary-row--pending') + (special ? ' scan-summary-row--special' : '') + '">');
            html.push('<div class="scan-summary-row__left">');
            html.push('<strong>' + escapeHtml(pieceLabel) + '</strong>');
            if (special) {
                html.push(' <span class="badge badge-gray badge-sm">Special</span>');
            }
            html.push('</div>');
            html.push('<div class="scan-summary-row__right">');
            html.push('<span class="scan-summary-pill ' + (uploaded ? 'scan-summary-pill--ok' : 'scan-summary-pill--wait') + '">');
            html.push(uploaded ? 'Uploadée' : 'En attente');
            html.push('</span>');
            if (uploaded && fileName) {
                html.push('<span class="scan-summary-filename">' + escapeHtml(fileName) + '</span>');
            }
            if (uploaded && uploadedAt) {
                html.push('<span class="scan-summary-date">' + escapeHtml(uploadedAt) + '</span>');
            }
            html.push('</div>');
            html.push('</li>');
        });
        html.push('</ul>');
        container.innerHTML = html.join('');
    }

    function updateWorkflowState(payload) {
        window.scanWorkflowState = {
            photoUploaded: !!(payload && payload.photoUploaded),
            signatureUploaded: !!(payload && payload.signatureUploaded),
            locked: !!(payload && payload.locked),
            scanComplet: !!(payload && payload.scanComplet),
            canFinalize: !!(payload && payload.scanComplet && !payload.locked)
        };

        var summarySection = getSummarySection();
        if (summarySection && payload && payload.locked) {
            summarySection.classList.add('scan-summary-box--locked');
        }

        if (typeof window.updateProgress === 'function') {
            window.updateProgress();
        }
    }

    function renderStatus(payload) {
        var completionMessage = document.getElementById('completionMessage');
        if (completionMessage) {
            if (payload && payload.locked) {
                completionMessage.className = 'completion-message complete';
                completionMessage.innerHTML = '<span class="icon">🔒</span> Dossier verrouille - plus aucune modification possible.';
            } else if (payload && payload.scanComplet) {
                completionMessage.className = 'completion-message complete';
                completionMessage.innerHTML = '<span class="icon">✓</span> Toutes les pieces attendues ont ete scannees. Vous pouvez maintenant verrouiller le dossier.';
            } else {
                completionMessage.className = 'completion-message incomplete';
                completionMessage.innerHTML = 'Des pieces manquent encore. Le bouton sera active quand toutes les pieces et la photo/signature seront presentes.';
            }
        }

        var finalizeBtn = document.getElementById('finalizeBtn');
        if (finalizeBtn && payload) {
            finalizeBtn.disabled = !payload.scanComplet || !!payload.locked;
        }

        var photoState = document.getElementById('scanPhotoState');
        if (photoState && payload) {
            photoState.textContent = payload.photoUploaded ? 'OK' : 'En attente';
        }

        var signatureState = document.getElementById('scanSignatureState');
        if (signatureState && payload) {
            signatureState.textContent = payload.signatureUploaded ? 'OK' : 'En attente';
        }
    }

    function refreshStatus() {
        var demandeId = getDemandeId();
        if (!demandeId) {
            return;
        }

        var appRoot = getAppRoot();
        var basePath = appRoot ? '/' + appRoot : '';
        var url = basePath + '/demande/' + demandeId + '/scan-status';

        fetch(url)
            .then(function (response) {
                if (!response.ok) {
                    throw new Error('HTTP ' + response.status);
                }
                return response.json();
            })
            .then(function (data) {
                var payload = data && data.success === false ? null : data;
                renderPieceList(payload && payload.pieces ? payload.pieces : []);
                renderStatus(payload || {});
                updateWorkflowState(payload || {});
            })
            .catch(function (error) {
                var summarySection = getSummarySection();
                if (summarySection) {
                    summarySection.setAttribute('data-scan-error', error.message || 'Erreur de chargement');
                }
            });
    }

    function init() {
        if (!getSummarySection()) {
            return;
        }

        refreshStatus();
    }

    window.addEventListener('scanStatusUpdated', refreshStatus);
    document.addEventListener('scan:pieceUploaded', refreshStatus);
    document.addEventListener('DOMContentLoaded', init);

    window.ScanSummary = {
        refreshStatus: refreshStatus
    };
})();
