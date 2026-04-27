/**
 * scanDemande.js  –  Sprint 3 / feature/scan-front
 *
 * Responsabilités :
 *  1. Gérer les checkboxes pour sélectionner les pièces
 *  2. Afficher/masquer le formulaire d'upload selon sélection
 *  3. Mettre à jour la barre de progression dynamiquement
 *  4. Valider les fichiers (type, taille) avant soumission
 *  5. Verrouiller le bouton upload pendant l'envoi (anti double-submit)
 *  6. Intercepter la soumission du formulaire "verrouiller" pour demander
 *     confirmation via confirm() — soumission native si accepté, annulation sinon.
 *
 * Note : aucun fetch/Ajax ici. Tout est POST natif + redirect côté serveur.
 */
(function () {
    'use strict';

    var ACCEPTED_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
    var MAX_BYTES      = 10 * 1024 * 1024; // 10 Mo

    function forEachNode(nodeList, cb) {
        Array.prototype.forEach.call(nodeList || [], cb);
    }

    function findByClassFrom(el, className) {
        var node = el;
        while (node && node !== document) {
            if (node.classList && node.classList.contains(className)) {
                return node;
            }
            node = node.parentNode;
        }
        return null;
    }

    /* ─────────────────────────────────────────────────────────────
       0. Gestion des checkboxes et progression dynamique
    ───────────────────────────────────────────────────────────── */
    function bindCheckboxes() {
        console.log('[bindCheckboxes] Début du binding');
        var checkboxes = document.querySelectorAll('.js-piece-checkbox');
        console.log('[bindCheckboxes] ' + checkboxes.length + ' checkboxes trouvées');
        
        forEachNode(checkboxes, function (checkbox) {
            checkbox.addEventListener('change', function () {
                var pieceId = this.dataset.pieceId;
                console.log('[bindCheckboxes] Checkbox ' + pieceId + ' -> ' + (this.checked ? 'COCHÉ' : 'DÉCOCHÉ'));
                
                var form = document.getElementById('form-' + pieceId);
                
                if (this.checked) {
                    // Afficher le formulaire d'upload
                    if (form) form.style.display = '';
                } else {
                    // Masquer le formulaire d'upload
                    if (form) form.style.display = 'none';
                    // Réinitialiser le fichier sélectionné
                    var input = document.getElementById('file-input-' + pieceId);
                    if (input) {
                        input.value = '';
                        var chosen = document.getElementById('chosen-' + pieceId);
                        if (chosen) chosen.textContent = 'Aucun fichier choisi';
                        var btn = document.getElementById('upload-btn-' + pieceId);
                        if (btn) btn.disabled = true;
                    }
                }
                
                window.updateProgress();
            });
        });
        console.log('[bindCheckboxes] Binding terminé');
    }

    /* ─────────────────────────────────────────────────────────────
       Mise à jour dynamique de la progression
    ───────────────────────────────────────────────────────────── */
    window.updateProgress = function () {
        console.log('[updateProgress] Calcul progression...');
        var totalCheckboxes = document.querySelectorAll('.js-piece-checkbox').length;
        var checkedCount = document.querySelectorAll('.js-piece-checkbox:checked').length;
        
        console.log('[updateProgress] ' + checkedCount + ' / ' + totalCheckboxes + ' pièces cochées');
        
        // Mettre à jour l'affichage du compteur
        var scannedEl = document.getElementById('scannedCount');
        if (scannedEl) scannedEl.textContent = checkedCount;
        var totalEl = document.getElementById('totalCount');
        if (totalEl) totalEl.textContent = totalCheckboxes;
        
        // Mettre à jour la barre
        var pct = (totalCheckboxes > 0) ? (checkedCount * 100 / totalCheckboxes) : 0;
        var barEl = document.getElementById('progressBarFill');
        if (barEl) {
            barEl.style.width = pct + '%';
            console.log('[updateProgress] Barre : ' + pct + '%');
        }
        
        // Activer/désactiver le bouton Finaliser
        var finalizeBtn = document.getElementById('finalizeBtn');
        if (finalizeBtn) {
            finalizeBtn.disabled = (checkedCount < totalCheckboxes);
            console.log('[updateProgress] Bouton finaliser : ' + (finalizeBtn.disabled ? 'DÉSACTIVÉ' : 'ACTIF'));
        }
    };

    /* ─────────────────────────────────────────────────────────────
       1 & 2. Input file → nom affiché + activation bouton submit
    ───────────────────────────────────────────────────────────── */
    function bindFileInputs() {
        forEachNode(document.querySelectorAll('.js-upload-input'), function (input) {
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
                    showInlineError(findByClassFrom(input, 'piece-card__upload-form'), err);
                    input.value = '';
                    if (chosen)    chosen.textContent = 'Aucun fichier choisi';
                    if (submitBtn) submitBtn.disabled = true;
                    return;
                }

                clearInlineError(findByClassFrom(input, 'piece-card__upload-form'));
                if (chosen)    chosen.textContent = file.name;
                if (submitBtn) submitBtn.disabled = false;
            });
        });
    }

    /* ─────────────────────────────────────────────────────────────
       3 & 4. Submit upload : validation + verrouillage bouton
    ───────────────────────────────────────────────────────────── */
    function bindUploadForms() {
        forEachNode(document.querySelectorAll('.piece-card__upload-form'), function (form) {
            form.addEventListener('submit', function (e) {
                e.preventDefault();

                var input = form.querySelector('.js-upload-input');
                var btn = form.querySelector('.js-upload-btn');
                var pieceId = btn ? btn.getAttribute('data-piece-id') : null;

                if (!input || !input.files || !input.files.length) {
                    showInlineError(form, 'Veuillez sélectionner un fichier.');
                    return;
                }

                var err = validateFile(input.files[0]);
                if (err) {
                    showInlineError(form, err);
                    return;
                }

                /* Verrouille pour éviter double-submit */
                if (btn) {
                    btn.disabled    = true;
                    btn.textContent = 'Envoi en cours...';
                }

                clearInlineError(form);

                fetch(form.action, {
                    method: 'POST',
                    body: new FormData(form)
                })
                .then(function (res) { return res.json(); })
                .then(function (json) {
                    showUploadJsonResult(json, false);

                    if (pieceId) {
                        var check = document.getElementById('check-' + pieceId);
                        if (check) check.checked = true;
                        var chosen = document.getElementById('chosen-' + pieceId);
                        if (chosen && input.files && input.files.length) {
                            chosen.textContent = input.files[0].name;
                        }
                    }

                    if (btn) {
                        btn.textContent = 'Uploadé';
                        btn.disabled = true;
                    }

                    window.updateProgress();
                })
                .catch(function (error) {
                    console.error('[upload] erreur', error);
                    showUploadJsonResult({
                        status: 'error',
                        message: 'Upload échoué (dummy). Vérifiez la route.'
                    }, true);

                    if (btn) {
                        btn.disabled = false;
                        btn.textContent = 'Uploader cette pièce';
                    }
                });
            });
        });
    }

    function showUploadJsonResult(payload, isError) {
        var target = document.getElementById('uploadJsonResult');
        if (!target) return;

        var inner = payload;
        if (payload && payload.data) inner = payload.data;

        target.className = (isError ? 'error-banner' : 'success-banner') + ' flash-banner';
        target.textContent = 'Réponse JSON upload: ' + JSON.stringify(inner);
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
        console.log('[JS DOMContentLoaded] Initialisation du module scan');
        bindCheckboxes();
        bindFileInputs();
        bindUploadForms();
        bindVerrouillerForm();
        console.log('[JS DOMContentLoaded] Initialisation terminée');
    });

})();