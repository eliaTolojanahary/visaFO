/**
 * scanDemande.js  –  Sprint 3 / feature/scan-front
 *
 * Responsabilités :
 *  1. Afficher le nom du fichier choisi dans le label stylisé
 *  2. Activer le bouton "Uploader" quand un fichier est sélectionné
 *  3. Valider localement (type, taille) avant soumission upload
 *  4. Verrouiller le bouton upload pendant l'envoi (anti double-submit)
 *  5. Intercepter la soumission du formulaire "verrouiller" pour demander
 *     confirmation via confirm() — soumission native si accepté, annulation sinon.
 *
 * Note : aucun fetch/Ajax ici. Tout est POST natif + redirect côté serveur.
 */
(function () {
    'use strict';

    const ACCEPTED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    const MAX_BYTES      = 10 * 1024 * 1024; // 10 Mo

    /* ─────────────────────────────────────────────────────────────
       1 & 2. Input file → nom affiché + activation bouton submit
    ───────────────────────────────────────────────────────────── */
    function bindFileInputs() {
        document.querySelectorAll('.js-upload-input').forEach(function (input) {
            input.addEventListener('change', function () {
                var pieceId   = input.dataset.pieceId;
                var chosen    = document.getElementById('chosen-' + pieceId);
                var submitBtn = document.querySelector(
                    '.js-upload-btn[data-piece-id="' + pieceId + '"]'
                );

                if (!input.files || !input.files.length) {
                    if (chosen)    chosen.textContent = 'Aucun fichier choisi';
                    if (submitBtn) submitBtn.disabled = true;
                    return;
                }

                var file = input.files[0];
                var err  = validateFile(file);

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

    /* ─────────────────────────────────────────────────────────────
       3 & 4. Submit upload : validation + verrouillage bouton
    ───────────────────────────────────────────────────────────── */
    function bindUploadForms() {
        document.querySelectorAll('.piece-card__upload-form').forEach(function (form) {
            form.addEventListener('submit', function (e) {
                var input = form.querySelector('.js-upload-input');

                if (!input || !input.files || !input.files.length) {
                    e.preventDefault();
                    return;
                }

                var err = validateFile(input.files[0]);
                if (err) {
                    e.preventDefault();
                    showInlineError(form, err);
                    return;
                }

                /* Verrouille pour éviter double-submit */
                var btn = form.querySelector('.js-upload-btn');
                if (btn) {
                    btn.disabled    = true;
                    btn.textContent = 'Envoi en cours…';
                }
            });
        });
    }

    /* ─────────────────────────────────────────────────────────────
       5. Formulaire verrouiller : confirm() avant soumission native.
          Si l'utilisateur annule → preventDefault, rien n'est envoyé.
          Si l'utilisateur confirme → le navigateur soumet normalement.
    ───────────────────────────────────────────────────────────── */
    function bindVerrouillerForm() {
        var form = document.getElementById('verrouillerForm');
        if (!form) return;

        form.addEventListener('submit', function (e) {
            var confirmed = confirm(
                'Toutes les pièces sont scannées. Verrouiller définitivement le dossier ?'
            );
            if (!confirmed) {
                e.preventDefault();
            }
            /* Si confirmed : soumission native, pas de JS supplémentaire. */
        });
    }

    /* ─────────────────────────────────────────────────────────────
       Validation fichier
    ───────────────────────────────────────────────────────────── */
    function validateFile(file) {
        if (ACCEPTED_TYPES.indexOf(file.type) === -1) {
            return 'Format non accepté. Utilisez PDF, JPG ou PNG.';
        }
        if (file.size > MAX_BYTES) {
            return 'Fichier trop volumineux (max 10 Mo).';
        }
        return null;
    }

    /* ─────────────────────────────────────────────────────────────
       Messages d'erreur inline (sous chaque formulaire upload)
    ───────────────────────────────────────────────────────────── */
    function showInlineError(form, message) {
        if (!form) return;
        var err = form.querySelector('.upload-form-error');
        if (!err) {
            err = document.createElement('div');
            err.className    = 'upload-form-error error-text';
            err.style.display = 'block';
            form.appendChild(err);
        }
        err.textContent = message;
    }

    function clearInlineError(form) {
        if (!form) return;
        var err = form.querySelector('.upload-form-error');
        if (err) err.textContent = '';
    }

    /* ─────────────────────────────────────────────────────────────
       Init
    ───────────────────────────────────────────────────────────── */
    window.addEventListener('DOMContentLoaded', function () {
        bindFileInputs();
        bindUploadForms();
        bindVerrouillerForm();
    });

})();