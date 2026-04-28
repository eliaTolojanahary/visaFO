/**
 * dynamicPieces.js
 * 
 * Gère l'affichage dynamique des pièces justificatives selon le profil
 * et le type de demande sélectionnés dans le formulaire.
 * 
 * Mettre en place quand vous voudrez que les checkboxes changent
 * en temps réel selon les sélections utilisateur.
 */

(function() {
    'use strict';

    // ====================================
    // CONFIGURATION DES PIÈCES PAR PROFIL
    // ====================================
    const PIECES_CONFIG = {
        // Récupérées du contrôleur via les attributs request
        // Ceci doit être hydraté par les données JSP
        commun: [],      // piecesCommunes
        investisseur: [], // piecesInvestisseur
        travailleur: []  // piecesTravailleur
    };

    // ====================================
    // INITIALISATION
    // ====================================
    function init() {
        // Charger les données des variables globales JSP si elles existent
        loadPiecesFromPage();
        
        // Écouter les changements de profil
        const profilRadios = document.querySelectorAll('input[name="profil"]');
        profilRadios.forEach(radio => {
            radio.addEventListener('change', updatePiecesList);
        });
        
        // Écouter les changements de type de demande
        const typeDemande = document.getElementById('typeDemande');
        if (typeDemande) {
            typeDemande.addEventListener('change', updatePiecesList);
        }
        
        // Affichage initial
        updatePiecesList();
    }

    // ====================================
    // CHARGER LES DONNÉES DEPUIS LA PAGE
    // ====================================
    function loadPiecesFromPage() {
        // Option 0 : Objet global JS injecté depuis la JSP
        if (window.PIECES_DATA && typeof window.PIECES_DATA === 'object') {
            PIECES_CONFIG.commun = window.PIECES_DATA.commun || [];
            PIECES_CONFIG.investisseur = window.PIECES_DATA.investisseur || [];
            PIECES_CONFIG.travailleur = window.PIECES_DATA.travailleur || [];
            return;
        }

        // Supposant que le contrôleur a exposé ces données en variables globales
        // ou via data attributes. Sinon, vous devez les passer ainsi :
        
        // Option 1 : Data attributes sur body
        const body = document.body;
        const piecesData = body.dataset.pieces;
        if (piecesData) {
            try {
                const parsed = JSON.parse(piecesData);
                PIECES_CONFIG.commun = parsed.commun || [];
                PIECES_CONFIG.investisseur = parsed.investisseur || [];
                PIECES_CONFIG.travailleur = parsed.travailleur || [];
            } catch (e) {
                console.warn('Erreur parsing pièces:', e);
            }
        }
        
        // Option 2 : Si vous passez les données en inline JSON sur une balise script
        const scriptData = document.getElementById('piecesDataScript');
        if (scriptData && scriptData.textContent) {
            try {
                const data = JSON.parse(scriptData.textContent);
                PIECES_CONFIG.commun = data.commun || [];
                PIECES_CONFIG.investisseur = data.investisseur || [];
                PIECES_CONFIG.travailleur = data.travailleur || [];
            } catch (e) {
                console.warn('Erreur parsing data script:', e);
            }
        }
    }

    // ====================================
    // METTRE À JOUR LA LISTE DES PIÈCES
    // ====================================
    function updatePiecesList() {
        const selectedProfil = document.querySelector('input[name="profil"]:checked')?.value || '';
        const checkedPieceIds = getCheckedPieceIds();

        const sections = [];
        sections.push({
            key: 'commun',
            title: 'Pieces communes',
            pieces: deduplicatePieces(PIECES_CONFIG.commun)
        });

        if (selectedProfil === 'investisseur') {
            sections.push({
                key: 'specific-investisseur',
                title: 'Pieces specifiques - Investisseur',
                pieces: deduplicatePieces(PIECES_CONFIG.investisseur)
            });
        } else if (selectedProfil === 'travailleur') {
            sections.push({
                key: 'specific-travailleur',
                title: 'Pieces specifiques - Travailleur',
                pieces: deduplicatePieces(PIECES_CONFIG.travailleur)
            });
        } else {
            sections.push({
                key: 'specific-none',
                title: 'Pieces specifiques',
                pieces: [],
                emptyMessage: 'Choisissez un profil pour afficher les pieces specifiques.'
            });
        }

        renderPieceSections(sections, checkedPieceIds);
    }

    // ====================================
    // AFFICHER LES PIÈCES
    // ====================================
    function renderPieceSections(sections, checkedPieceIds) {
        const pieceList = document.getElementById('pieceList');
        
        if (!pieceList) {
            console.warn('pieceList container not found');
            return;
        }
        
        // Vider l'ancienne liste
        pieceList.innerHTML = '';
        
        if (!sections || sections.length === 0) {
            pieceList.innerHTML = '<p class="hint-text">Aucune pièce justificative à afficher.</p>';
            return;
        }

        sections.forEach(section => {
            const miniSection = document.createElement('section');
            miniSection.className = 'piece-mini-section';
            miniSection.dataset.sectionKey = section.key;

            const title = document.createElement('h3');
            title.className = 'piece-mini-section__title';
            title.textContent = section.title;
            miniSection.appendChild(title);

            if (!section.pieces || section.pieces.length === 0) {
                const empty = document.createElement('p');
                empty.className = 'hint-text piece-mini-section__hint';
                empty.textContent = section.emptyMessage || 'Aucune piece dans cette section.';
                miniSection.appendChild(empty);
                pieceList.appendChild(miniSection);
                return;
            }

            const list = document.createElement('div');
            list.className = 'piece-mini-section__list';
            section.pieces.forEach(piece => {
                const card = createPieceCard(piece, checkedPieceIds);
                list.appendChild(card);
            });

            miniSection.appendChild(list);
            pieceList.appendChild(miniSection);
        });
        
        // Ajouter les event listeners aux checkboxes
        attachCheckboxListeners();
        updatePieceCount();
        updateRecapPieces();
        dispatchPiecesUpdated();
    }

    // ====================================
    // CRÉER UNE CARTE DE PIÈCE
    // ====================================
    function createPieceCard(piece, checkedPieceIds) {
        const div = document.createElement('div');
        div.className = 'piece-card';
        div.id = `piece-${piece.id}`;
        
        const checked = checkedPieceIds && checkedPieceIds.has(String(piece.id)) ? 'checked' : '';
        const dotClass = checked ? 'dot--green' : 'dot--gray';
        const uploadDisplay = checked ? '' : 'style="display:none;"';
        
        div.innerHTML = `
            <div class="piece-card__info">
                <input type="checkbox" 
                       class="piece-card__checkbox js-piece-checkbox"
                       id="check-${piece.id}"
                       data-piece-id="${piece.id}"
                       name="selectedPieces"
                       value="${piece.id}"
                       ${checked}>
                <label for="check-${piece.id}" class="piece-card__checkbox-label">
                    <span class="piece-card__status-dot ${dotClass}"></span>
                    <span class="piece-card__label">${escapeHtml(piece.libelle)}</span>
                </label>
            </div>

            <div class="piece-card__right">
                <div class="piece-card__upload-form" id="form-${piece.id}" ${uploadDisplay}>
                    <label class="piece-card__file-label" for="file-input-${piece.id}">
                        <input type="file"
                               id="file-input-${piece.id}"
                               name="piece_file_${piece.id}"
                               class="visually-hidden scan-piece-input"
                               accept="image/jpeg,image/png,application/pdf"
                               data-piece-id="${piece.id}">
                        <span class="piece-card__file-trigger btn-alt btn-sm">Choisir un fichier</span>
                        <span class="piece-card__file-chosen" id="chosen-${piece.id}">Aucun fichier choisi</span>
                    </label>
                    <div class="piece-status" id="status-${piece.id}">
                        <div class="no-file"><span class="icon icon-info"></span> Aucun fichier</div>
                    </div>
                </div>
            </div>
        `;

        if (checked) {
            div.classList.add('piece-card--done');
        }
        
        return div;
    }

    function deduplicatePieces(pieces) {
        const byId = new Map();
        (pieces || []).forEach(piece => {
            if (!piece || piece.id == null) return;
            const key = String(piece.id);
            if (!byId.has(key)) {
                byId.set(key, piece);
            }
        });
        return Array.from(byId.values());
    }

    // ====================================
    // VÉRIFIER SI UNE PIÈCE EST COCHÉE
    // ====================================
    function getCheckedPieceIds() {
        const checkedSet = new Set();
        const checked = document.querySelectorAll('.js-piece-checkbox:checked');
        checked.forEach(checkbox => {
            checkedSet.add(String(checkbox.value));
        });
        return checkedSet;
    }

    // ====================================
    // AJOUTER LES LISTENERS AUX CHECKBOXES
    // ====================================
    function attachCheckboxListeners() {
        const checkboxes = document.querySelectorAll('.js-piece-checkbox');
        checkboxes.forEach(checkbox => {
            checkbox.addEventListener('change', onPieceCheckboxChange);
        });
    }

    // ====================================
    // HANDLER CHANGEMENT CHECKBOX
    // ====================================
    function onPieceCheckboxChange(evt) {
        const pieceId = evt.target.dataset.pieceId;
        const isChecked = evt.target.checked;
        
        // Mettre à jour le style de la card
        const card = document.getElementById(`piece-${pieceId}`);
        if (card) {
            const uploadForm = card.querySelector(`#form-${pieceId}`);
            if (isChecked) {
                card.classList.add('piece-card--done');
                if (uploadForm) uploadForm.style.display = '';
                const dot = card.querySelector('.piece-card__status-dot');
                if (dot) {
                    dot.className = 'piece-card__status-dot dot--green';
                }
            } else {
                card.classList.remove('piece-card--done');
                if (uploadForm) uploadForm.style.display = 'none';

                const fileInput = card.querySelector(`#file-input-${pieceId}`);
                const chosen = card.querySelector(`#chosen-${pieceId}`);
                const status = card.querySelector(`#status-${pieceId}`);
                if (fileInput) fileInput.value = '';
                if (chosen) chosen.textContent = 'Aucun fichier choisi';
                if (status) {
                    status.innerHTML = '<div class="no-file"><span class="icon icon-info"></span> Aucun fichier</div>';
                }
                const dot = card.querySelector('.piece-card__status-dot');
                if (dot) {
                    dot.className = 'piece-card__status-dot dot--gray';
                }
            }
        }
        
        // Mettre à jour le compteur et le recap
        updatePieceCount();
        updateRecapPieces();
    }

    // ====================================
    // METTRE À JOUR LE COMPTEUR
    // ====================================
    function updatePieceCount() {
        const total = document.querySelectorAll('.js-piece-checkbox').length;
        const checked = document.querySelectorAll('.js-piece-checkbox:checked').length;
        
        const scannedCountEl = document.getElementById('scannedCount');
        const totalCountEl = document.getElementById('totalCount');
        
        if (scannedCountEl) scannedCountEl.textContent = checked;
        if (totalCountEl) totalCountEl.textContent = total;

        const progressBarFill = document.getElementById('progressBarFill');
        if (progressBarFill) {
            const pct = total > 0 ? Math.round((checked / total) * 100) : 0;
            progressBarFill.style.width = `${pct}%`;
        }
    }

    // ====================================
    // METTRE À JOUR LE RÉCAPITULATIF
    // ====================================
    function updateRecapPieces() {
        const recapPieces = document.getElementById('recapPieces');
        if (!recapPieces) return;
        
        const checkedCheckboxes = document.querySelectorAll('.js-piece-checkbox:checked');
        
        if (checkedCheckboxes.length === 0) {
            recapPieces.innerHTML = '<li>Aucune pièce sélectionnée</li>';
            return;
        }
        
        let html = '';
        checkedCheckboxes.forEach(checkbox => {
            const label = document.querySelector(`label[for="${checkbox.id}"] .piece-card__label`)?.textContent;
            if (label) {
                html += `<li>${escapeHtml(label)}</li>`;
            }
        });
        
        recapPieces.innerHTML = html;
    }

    function dispatchPiecesUpdated() {
        document.dispatchEvent(new CustomEvent('pieces:updated'));
    }

    // ====================================
    // UTILITAIRE : ESCAPER HTML
    // ====================================
    function escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return String(text || '').replace(/[&<>"']/g, m => map[m]);
    }

    // ====================================
    // DÉMARRAGE
    // ====================================
    window.refreshDynamicPieces = updatePiecesList;

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
