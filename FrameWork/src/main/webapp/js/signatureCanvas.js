/**
 * signatureCanvas.js  –  sprint5/feat/signature
 * Capture signature sur canvas HTML5.
 */
(function () {
    'use strict';

    document.addEventListener('DOMContentLoaded', function () {
        var bloc     = document.getElementById('signatureBloc');
        if (!bloc) return;

        var canvas   = document.getElementById('signatureCanvas');
        var wrapper  = document.getElementById('signatureCanvasWrapper');
        var ctx      = canvas.getContext('2d');
        var btnClear   = document.getElementById('signatureBtnClear');
        var btnPreview = document.getElementById('signatureBtnPreview');
        var btnUpload  = document.getElementById('signatureBtnUpload');
        var preview    = document.getElementById('signaturePreview');
        var statusEl   = document.getElementById('signatureStatus');

        var demandeId = bloc.dataset.demandeId;
        var dossierId = bloc.dataset.dossierId;

        if (!demandeId) {
            console.error('[signatureCanvas] data-demande-id manquant sur #signatureBloc');
            return;
        }
        // dossierId peut être vide si non transmis – on continue quand même
        // (l'endpoint backend devra gérer le cas dossierId=0 ou null)

        var drawing  = false;
        var hasDrawn = false;
        var lastSignaturePieceRefId = null;

        // ── Init taille canvas ────────────────────────────────────────────
        function setupCanvas() {
            var w = wrapper ? wrapper.clientWidth : (canvas.parentElement ? canvas.parentElement.clientWidth : 600);
            if (!w || w < 10) w = 600;
            canvas.width  = w;
            canvas.height = 180;
            ctx.fillStyle   = '#ffffff';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.strokeStyle = '#111827';
            ctx.lineWidth   = 2.5;
            ctx.lineCap     = 'round';
            ctx.lineJoin    = 'round';
        }

        // Attendre que le layout soit calculé
        requestAnimationFrame(function () {
            setupCanvas();
        });

        window.addEventListener('resize', function () {
            var snapshot = hasDrawn ? canvas.toDataURL() : null;
            setupCanvas();
            if (snapshot) {
                var img = new Image();
                img.onload = function () { ctx.drawImage(img, 0, 0); };
                img.src = snapshot;
            }
        });

        // ── Coordonnées ───────────────────────────────────────────────────
        function pos(e) {
            var r  = canvas.getBoundingClientRect();
            var sx = canvas.width  / r.width;
            var sy = canvas.height / r.height;
            var s  = e.touches ? e.touches[0] : e;
            return { x: (s.clientX - r.left) * sx, y: (s.clientY - r.top) * sy };
        }

        // ── Dessin souris ─────────────────────────────────────────────────
        canvas.addEventListener('mousedown', function (e) {
            drawing = true;
            var p = pos(e);
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
        });

        canvas.addEventListener('mousemove', function (e) {
            if (!drawing) return;
            var p = pos(e);
            ctx.lineTo(p.x, p.y);
            ctx.stroke();
            firstStroke();
        });

        canvas.addEventListener('mouseup',    stop);
        canvas.addEventListener('mouseleave', stop);

        // ── Dessin tactile ────────────────────────────────────────────────
        canvas.addEventListener('touchstart', function (e) {
            e.preventDefault();
            drawing = true;
            var p = pos(e);
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
        }, { passive: false });

        canvas.addEventListener('touchmove', function (e) {
            e.preventDefault();
            if (!drawing) return;
            var p = pos(e);
            ctx.lineTo(p.x, p.y);
            ctx.stroke();
            firstStroke();
        }, { passive: false });

        canvas.addEventListener('touchend',    stop);
        canvas.addEventListener('touchcancel', stop);

        function stop() {
            if (drawing) { drawing = false; ctx.beginPath(); }
        }

        function firstStroke() {
            if (hasDrawn) return;
            hasDrawn = true;
            if (wrapper) wrapper.classList.add('has-drawing');
        }

        // ── Effacer ───────────────────────────────────────────────────────
        btnClear.addEventListener('click', function () {
            setupCanvas();
            hasDrawn = false;
            if (wrapper) wrapper.classList.remove('has-drawing');
            if (preview) { preview.src = ''; preview.style.display = 'none'; }
            setStatus('', '');
        });

        // ── Prévisualiser ─────────────────────────────────────────────────
        if (btnPreview) {
            btnPreview.addEventListener('click', function () {
                if (!hasDrawn) { setStatus('error', 'Dessinez votre signature d\'abord.'); return; }
                preview.src = canvas.toDataURL('image/png');
                preview.style.display = 'block';
                setStatus('', '');
            });
        }

        // ── Upload ────────────────────────────────────────────────────────
        btnUpload.addEventListener('click', function () {
            if (!hasDrawn) { setStatus('error', "Dessinez votre signature avant de l'enregistrer."); return; }

            var dataUrl = canvas.toDataURL('image/png');
            var b64 = dataUrl.split(',')[1] || '';
            if (Math.ceil(b64.length * 3 / 4) > 1048576) {
                setStatus('error', 'Signature trop grande (max 1 Mo). Simplifiez le tracé.');
                return;
            }

            setStatus('loading', 'Enregistrement…');
            btnUpload.disabled = true;

            var rawRoot = typeof window.APP_ROOT === 'string' ? window.APP_ROOT.trim() : '';
            var appRoot = rawRoot.replace(/^\/+/g, '').replace(/\/+$/g, '') || window.location.pathname.split('/')[1] || '';
            var url = (appRoot ? '/' + appRoot : '') + '/demande/' + demandeId + '/dossiers/' + (dossierId || '0') + '/signature';

            fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
                body: new URLSearchParams({
                    demandeId: String(demandeId),
                    dossierId: String(dossierId || '0'),
                    dataUrl: dataUrl
                }).toString()
            })
            .then(function (r) { return r.json(); })
            .then(function (d) {
                var payload = d && d.data ? d.data : d;

                if (payload && payload.success) {
                    // Stocker l'id réel reçu du backend pour markCardScanned
                    if (payload.pieceRefId) lastSignaturePieceRefId = payload.pieceRefId;
                    setStatus('success', 'Signature enregistrée' + (payload.nomFichier ? ' (' + payload.nomFichier + ')' : '') + '.');
                    markCardScanned(payload.nomFichier || 'signature.png');
                    document.dispatchEvent(new CustomEvent('scan:pieceUploaded', { detail: { demandeComplete: payload.demandeComplete } }));
                } else {
                    setStatus('error', (payload && payload.error) ? payload.error : "Erreur lors de l'enregistrement.");
                }
            })
            .catch(function (e) { setStatus('error', 'Erreur réseau : ' + e.message); })
            .finally(function () { btnUpload.disabled = false; });
        });

        // ── Helpers ───────────────────────────────────────────────────────
        function setStatus(type, msg) {
            if (!statusEl) return;
            statusEl.textContent = msg;
            statusEl.className = 'signature-status' + (type ? ' signature-status--' + type : '');
        }

        function markCardScanned(fileName) {
            // Chercher la card Signature par data-libelle ou par id recu du backend
            // On cherche d'abord via l'id transmis dans la réponse, sinon on scanne le DOM
            var card = null;
            if (lastSignaturePieceRefId) {
                card = document.getElementById('piece-' + lastSignaturePieceRefId);
            }
            if (!card) {
                // Fallback : parcourir toutes les cards et trouver "Signature"
                var cards = document.querySelectorAll('.piece-card');
                for (var i = 0; i < cards.length; i++) {
                    var lbl = cards[i].querySelector('.piece-card__label');
                    if (lbl && lbl.textContent.toLowerCase().indexOf('signature') !== -1) {
                        card = cards[i];
                        break;
                    }
                }
            }
            if (!card) return;
            card.classList.add('piece-card--done');
            var cb = card.querySelector('.js-piece-checkbox');
            if (cb) { cb.checked = true; cb.dataset.serverScanned = '1'; }
            var dot = card.querySelector('.piece-card__status-dot');
            if (dot) { dot.classList.remove('dot--gray'); dot.classList.add('dot--green'); }
            var meta = card.querySelector('.piece-card__file-meta');
            if (meta) {
                meta.classList.remove('piece-card__file-meta--empty');
                meta.innerHTML = '';

                var nameSpan = document.createElement('span');
                nameSpan.className = 'piece-card__filename';
                nameSpan.textContent = String(fileName);

                var badge = document.createElement('span');
                badge.className = 'badge badge-green badge-sm';
                badge.textContent = 'Scanned';

                meta.appendChild(nameSpan);
                meta.appendChild(badge);
            }
        }
    });
})();