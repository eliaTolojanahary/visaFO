/**
 * scanDemande.js  –  Sprint 3 / feature/scan-front
 *
 * Responsabilités :
 *  - Écouter les inputs file et déclencher l'upload vers /demande/{id}/scan/upload
 *  - Mettre à jour l'état visuel de chaque pièce (barre de progression, badge, nom fichier)
 *  - Recalculer la progression globale
 *  - Activer le bouton "Finaliser le scan" quand toutes les pièces sont scannées
 *  - Afficher les erreurs (taille, type, réseau)
 */
(function () {
    'use strict';

    /* ── Constantes ────────────────────────────────────────────── */
    const ACCEPTED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    const MAX_FILE_SIZE  = 10 * 1024 * 1024; // 10 Mo

    /* ── Utilitaires DOM ───────────────────────────────────────── */
    function byId(id) { return document.getElementById(id); }

    function showGlobalMessage(text, type) {
        const banner = byId('globalMessage');
        if (!banner) return;
        banner.textContent = text;
        banner.className   = type === 'success' ? 'success-banner' : 'error-banner';
        banner.style.display = 'block';
        setTimeout(function () {
            banner.className   = 'hidden';
            banner.style.display = '';
        }, 5000);
    }

    /* ── Progression globale ───────────────────────────────────── */
    function refreshGlobalProgress() {
        const allCards    = document.querySelectorAll('.piece-card');
        const doneCards   = document.querySelectorAll('.piece-card[data-scanned="true"]');
        const total       = allCards.length;
        const done        = doneCards.length;
        const pct         = total > 0 ? Math.round((done / total) * 100) : 0;

        const fill        = byId('progressBarFill');
        const count       = byId('progressCount');
        const finalizeBtn = byId('finalizeScanBtn');

        if (fill)  fill.style.width = pct + '%';
        if (count) count.textContent = done + ' / ' + total + ' pièces';
        if (finalizeBtn) finalizeBtn.disabled = (done < total);
    }

    /* ── Mise à jour d'une pièce après succès ─────────────────── */
    function markPieceAsDone(card, fileName) {
        card.dataset.scanned = 'true';
        card.classList.add('piece-card--done');

        /* Dot vert */
        const dot = card.querySelector('.piece-card__status-dot');
        if (dot) { dot.classList.remove('dot--gray'); dot.classList.add('dot--green'); }

        /* Actions : remplacer le bouton upload par nom + badge */
        const actionsZone = card.querySelector('.piece-card__actions');
        if (actionsZone) {
            actionsZone.innerHTML =
                '<span class="piece-card__filename" title="' + fileName + '">' + fileName + '</span>' +
                '<button type="button" class="btn-alt btn-sm js-replace-btn" data-piece-id="' + card.dataset.pieceId + '">Remplacer</button>' +
                '<span class="badge badge-green badge-sm">Scanné</span>';

            /* Ré-attacher l'event sur le nouveau bouton remplacer */
            const replaceBtn = actionsZone.querySelector('.js-replace-btn');
            if (replaceBtn) {
                replaceBtn.addEventListener('click', function () {
                    triggerFileInput(card.dataset.pieceId, card.closest('[data-demande-id]'));
                });
            }
        }

        refreshGlobalProgress();
    }

    /* ── Affichage/masquage de la progression individuelle ──────── */
    function showPieceProgress(pieceId, visible) {
        const el = byId('upload-progress-' + pieceId);
        if (!el) return;
        el.classList.toggle('hidden', !visible);
    }

    function setPieceProgressValue(pieceId, pct) {
        const el = byId('upload-progress-' + pieceId);
        if (!el) return;
        const fill = el.querySelector('.mini-progress-fill');
        if (fill) fill.style.width = pct + '%';
    }

    function showPieceError(pieceId, message) {
        const el = byId('upload-error-' + pieceId);
        if (!el) return;
        el.textContent = message;
        el.classList.remove('hidden');
        setTimeout(function () { el.classList.add('hidden'); }, 6000);
    }

    /* ── Validation locale du fichier ──────────────────────────── */
    function validateFile(file) {
        if (!ACCEPTED_TYPES.includes(file.type)) {
            return 'Format non accepté. Utilisez PDF, JPG ou PNG.';
        }
        if (file.size > MAX_FILE_SIZE) {
            return 'Fichier trop volumineux (max 10 Mo).';
        }
        return null;
    }

    /* ── Upload XHR avec progression ───────────────────────────── */
    function uploadFile(file, pieceId, demandeId, card) {
        const error = validateFile(file);
        if (error) { showPieceError(pieceId, error); return; }

        const formData = new FormData();
        formData.append('file',      file);
        formData.append('piece_id',  pieceId);
        formData.append('demande_id', demandeId);

        const xhr = new XMLHttpRequest();

        /* Progression upload */
        xhr.upload.addEventListener('progress', function (e) {
            if (e.lengthComputable) {
                setPieceProgressValue(pieceId, Math.round((e.loaded / e.total) * 100));
            }
        });

        xhr.addEventListener('load', function () {
            showPieceProgress(pieceId, false);
            if (xhr.status >= 200 && xhr.status < 300) {
                markPieceAsDone(card, file.name);
                showGlobalMessage('Pièce « ' + file.name + ' » enregistrée.', 'success');
            } else {
                showPieceError(pieceId, 'Erreur serveur (' + xhr.status + '). Réessayez.');
                showGlobalMessage('Échec de l\'envoi pour la pièce ' + pieceId + '.', 'error');
            }
        });

        xhr.addEventListener('error', function () {
            showPieceProgress(pieceId, false);
            showPieceError(pieceId, 'Erreur réseau. Vérifiez votre connexion.');
        });

        xhr.open('POST', '/demande/' + demandeId + '/scan/upload');
        showPieceProgress(pieceId, true);
        setPieceProgressValue(pieceId, 0);
        xhr.send(formData);
    }

    /* ── Déclencher un input file dynamique (pour "Remplacer") ── */
    function triggerFileInput(pieceId, demandeId) {
        const input = document.createElement('input');
        input.type   = 'file';
        input.accept = '.pdf,.jpg,.jpeg,.png';
        input.style.display = 'none';
        document.body.appendChild(input);

        input.addEventListener('change', function () {
            const file = input.files[0];
            if (!file) { document.body.removeChild(input); return; }
            const card = byId('piece-' + pieceId);
            if (card) uploadFile(file, pieceId, demandeId, card);
            document.body.removeChild(input);
        });

        input.click();
    }

    /* ── Bouton "Finaliser le scan" ─────────────────────────────── */
    function bindFinalizeButton() {
        const btn = byId('finalizeScanBtn');
        if (!btn) return;

        btn.addEventListener('click', function () {
            /* Récupère demandeId depuis n'importe quel input file présent */
            const anyInput = document.querySelector('.js-file-input');
            const demandeId = anyInput ? anyInput.dataset.demandeId : null;
            if (!demandeId) return;

            /* Confirmation simple */
            if (!confirm('Confirmer la finalisation du scan ? Cette action ne peut pas être annulée si le dossier est ensuite verrouillé.')) return;

            btn.disabled = true;
            btn.textContent = 'Finalisation…';

            fetch('/demande/' + demandeId + '/scan/finaliser', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(function (res) {
                if (res.ok) {
                    showGlobalMessage('Scan finalisé avec succès.', 'success');
                    /* Rafraîchit la page après 1.5 s pour afficher le nouveau statut */
                    setTimeout(function () { window.location.reload(); }, 1500);
                } else {
                    btn.disabled = false;
                    btn.textContent = 'Finaliser le scan';
                    showGlobalMessage('Erreur lors de la finalisation (' + res.status + ').', 'error');
                }
            })
            .catch(function () {
                btn.disabled = false;
                btn.textContent = 'Finaliser le scan';
                showGlobalMessage('Erreur réseau lors de la finalisation.', 'error');
            });
        });
    }

    /* ── Initialisation ─────────────────────────────────────────── */
    window.addEventListener('DOMContentLoaded', function () {

        /* Écoute tous les inputs file pour upload immédiat */
        document.querySelectorAll('.js-file-input').forEach(function (input) {
            input.addEventListener('change', function () {
                const file      = input.files[0];
                if (!file) return;
                const pieceId   = input.dataset.pieceId;
                const demandeId = input.dataset.demandeId;
                const card      = byId('piece-' + pieceId);
                if (card) uploadFile(file, pieceId, demandeId, card);
                /* Réinitialise l'input pour permettre re-sélection du même fichier */
                input.value = '';
            });
        });

        /* Boutons "Remplacer" déjà dans le DOM (pièces déjà scannées) */
        document.querySelectorAll('.js-replace-btn').forEach(function (btn) {
            btn.addEventListener('click', function () {
                const pieceId   = btn.dataset.pieceId;
                const anyInput  = document.querySelector('.js-file-input[data-demande-id]');
                const demandeId = anyInput ? anyInput.dataset.demandeId : null;
                if (demandeId) triggerFileInput(pieceId, demandeId);
            });
        });

        bindFinalizeButton();
        refreshGlobalProgress();
    });
})();

/**
 * scanDemande.js  –  Sprint 3 / feature/scan-front
 *
 * Responsabilités (upload géré par <form> POST natif) :
 *  1. Afficher le nom du fichier choisi dans le label stylisé
 *  2. Activer le bouton "Uploader" seulement quand un fichier est sélectionné
 *  3. Valider localement (type, taille) avant soumission — annule si invalide
 *  4. Mettre le formulaire en état "envoi en cours" pendant la soumission
 *  5. Bouton "Finaliser le scan" → POST fetch + redirect
 */
(function () {
    'use strict';

    /* ── Constantes ────────────────────────────────────────────── */
    const ACCEPTED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    const MAX_BYTES      = 10 * 1024 * 1024; // 10 Mo

    /* ──────────────────────────────────────────────────────────── */
    /* 1. Sélecteur fichier : nom affiché + activation du bouton   */
    /* ──────────────────────────────────────────────────────────── */

    function bindFileInputs() {
        document.querySelectorAll('.js-upload-input').forEach(function (input) {
            input.addEventListener('change', function () {
                const pieceId  = input.dataset.pieceId;
                const chosen   = document.getElementById('chosen-' + pieceId);
                const submitBtn = document.getElementById('upload-btn-' + pieceId);

                if (!input.files || !input.files.length) {
                    if (chosen)    chosen.textContent = 'Aucun fichier choisi';
                    if (submitBtn) submitBtn.disabled = true;
                    return;
                }

                const file = input.files[0];

                /* Validation locale immédiate */
                const err = validateFile(file);
                if (err) {
                    showInlineError(input.closest('.piece-card__upload-form'), err);
                    input.value = '';
                    if (chosen)    chosen.textContent = 'Aucun fichier choisi';
                    if (submitBtn) submitBtn.disabled = true;
                    return;
                }

                clearInlineError(input.closest('.piece-card__upload-form'));
                if (chosen)    chosen.textContent = file.name;
                if (submitBtn) submitBtn.disabled = false;
            });
        });
    }

    /* ──────────────────────────────────────────────────────────── */
    /* 2. Soumission du formulaire : état "en cours"               */
    /* ──────────────────────────────────────────────────────────── */

    function bindUploadForms() {
        document.querySelectorAll('.piece-card__upload-form').forEach(function (form) {
            form.addEventListener('submit', function (e) {
                const input = form.querySelector('.js-upload-input');

                /* Double-vérification côté JS avant envoi */
                if (!input || !input.files || !input.files.length) {
                    e.preventDefault();
                    return;
                }

                const err = validateFile(input.files[0]);
                if (err) {
                    e.preventDefault();
                    showInlineError(form, err);
                    return;
                }

                /* Verrouille le bouton pendant l'envoi (évite double-submit) */
                const btn = form.querySelector('.js-upload-btn');
                if (btn) {
                    btn.disabled    = true;
                    btn.textContent = 'Envoi en cours…';
                }
            });
        });
    }

    /* ──────────────────────────────────────────────────────────── */
    /* 3. Validation fichier                                        */
    /* ──────────────────────────────────────────────────────────── */

    function validateFile(file) {
        if (!ACCEPTED_TYPES.includes(file.type)) {
            return 'Format non accepté. Utilisez PDF, JPG ou PNG.';
        }
        if (file.size > MAX_BYTES) {
            return 'Fichier trop volumineux (max 10 Mo).';
        }
        return null;
    }

    /* ──────────────────────────────────────────────────────────── */
    /* 4. Messages d'erreur inline (sous le formulaire)            */
    /* ──────────────────────────────────────────────────────────── */

    function showInlineError(form, message) {
        if (!form) return;
        let err = form.querySelector('.upload-form-error');
        if (!err) {
            err = document.createElement('div');
            err.className = 'upload-form-error error-text';
            err.style.display = 'block';
            form.appendChild(err);
        }
        err.textContent = message;
    }

    function clearInlineError(form) {
        if (!form) return;
        const err = form.querySelector('.upload-form-error');
        if (err) err.textContent = '';
    }

    /* ──────────────────────────────────────────────────────────── */
    /* 5. Bouton "Finaliser le scan"                               */
    /* ──────────────────────────────────────────────────────────── */

    function bindFinalizeButton() {
        const btn = document.getElementById('finalizeScanBtn');
        if (!btn) return;

        btn.addEventListener('click', function () {
            const demandeId = btn.dataset.demandeId;
            if (!demandeId) return;

            if (!confirm(
                'Confirmer la finalisation du scan ?\n' +
                'Le dossier sera verrouillé et aucune modification ne sera possible.'
            )) return;

            btn.disabled    = true;
            btn.textContent = 'Finalisation…';

            fetch('/demande/' + demandeId + '/scan/finaliser', {
                method:  'POST',
                headers: { 'Content-Type': 'application/json' }
            })
            .then(function (res) {
                if (res.ok) {
                    /* Reload → le controller injecte flashMessage + statut mis à jour */
                    window.location.reload();
                } else {
                    btn.disabled    = false;
                    btn.textContent = 'Finaliser le scan';
                    showGlobalMessage('Erreur lors de la finalisation (' + res.status + ').', 'error');
                }
            })
            .catch(function () {
                btn.disabled    = false;
                btn.textContent = 'Finaliser le scan';
                showGlobalMessage('Erreur réseau lors de la finalisation.', 'error');
            });
        });
    }

    /* ──────────────────────────────────────────────────────────── */
    /* Utilitaire message global (uniquement pour Finaliser)       */
    /* ──────────────────────────────────────────────────────────── */

    function showGlobalMessage(text, type) {
        const banner = document.getElementById('globalMessage');
        if (!banner) return;
        banner.textContent = text;
        banner.className   = type === 'success' ? 'success-banner' : 'error-banner';
        banner.style.display = 'block';
        setTimeout(function () {
            banner.className     = 'hidden';
            banner.style.display = '';
        }, 6000);
    }

    /* ──────────────────────────────────────────────────────────── */
    /* Init                                                         */
    /* ──────────────────────────────────────────────────────────── */

    window.addEventListener('DOMContentLoaded', function () {
        bindFileInputs();
        bindUploadForms();
        bindFinalizeButton();
    });

})();