/**
 * Module de capture de photo d'identité via webcam
 * Sprint 5 - Photo d'Identité (Webcam)
 * 
 * Fonctionnalités :
 * - Accès à la webcam du système
 * - Capture photo en direct
 * - Prévisualisation de la photo capturée
 * - Upload vers l'API backend
 * - Affichage du statut upload
 * - Rafraîchissement automatique du résumé du scan
 */

(function() {
    'use strict';

    // Configuration
    const CONFIG = {
        videoWidth: 480,
        videoHeight: 360,
        canvasWidth: 480,
        canvasHeight: 360,
        uploadTimeout: 30000, // 30 secondes
        maxRetries: 3
    };

    // État du module
    let state = {
        videoStream: null,
        capturedPhoto: null,
        isCapturing: false,
        isUploading: false,
        uploadRetries: 0
    };

    function getAppRoot() {
        var root = '';
        if (typeof window.APP_ROOT === 'string' && window.APP_ROOT.trim().length > 0) {
            root = window.APP_ROOT.trim();
        } else {
            var segments = window.location.pathname.split('/');
            root = segments.length > 1 ? segments[1] : '';
        }
        return root.replace(/^\/+/g, '').replace(/\/+$/g, '');
    }

    /**
     * Initialisation du module
     */
    function init() {
        const photoBlock = document.getElementById('photo-identite-block');
        if (!photoBlock) {
            console.warn('[PhotoWebcam] Bloc photo non trouvé dans le DOM');
            return;
        }

        setupEventListeners();
        logDebug('Module PhotoWebcam initialisé');
    }

    /**
     * Configuration des écouteurs d'événements
     */
    function setupEventListeners() {
        const startCameraBtn = document.getElementById('startCameraBtn');
        const stopCameraBtn = document.getElementById('stopCameraBtn');
        const capturePhotoBtn = document.getElementById('capturePhotoBtn');
        const retakeCameraBtn = document.getElementById('retakeCameraBtn');
        const uploadPhotoBtn = document.getElementById('uploadPhotoBtn');

        if (startCameraBtn) {
            startCameraBtn.addEventListener('click', handleStartCamera);
        }
        if (stopCameraBtn) {
            stopCameraBtn.addEventListener('click', handleStopCamera);
        }
        if (capturePhotoBtn) {
            capturePhotoBtn.addEventListener('click', handleCapturePhoto);
        }
        if (retakeCameraBtn) {
            retakeCameraBtn.addEventListener('click', handleRetakePhoto);
        }
        if (uploadPhotoBtn) {
            uploadPhotoBtn.addEventListener('click', handleUploadPhoto);
        }
    }

    /**
     * Démarrer la capture vidéo webcam
     */
    function handleStartCamera() {
        logDebug('Demande d\'accès à la webcam...');
        
        const constraints = {
            video: {
                width: { ideal: CONFIG.videoWidth },
                height: { ideal: CONFIG.videoHeight },
                facingMode: 'user'
            },
            audio: false
        };

        navigator.mediaDevices.getUserMedia(constraints)
            .then(stream => {
                state.videoStream = stream;
                const videoElement = document.getElementById('cameraVideo');
                const cameraContainer = document.querySelector('.camera-container');
                if (cameraContainer) {
                    cameraContainer.style.display = 'block';
                }
                if (videoElement) {
                    videoElement.srcObject = stream;
                    videoElement.style.display = 'block';
                    videoElement.play().catch(err => {
                        logError('Erreur lors de la lecture vidéo:', err);
                        showError('Impossible de démarrer la vidéo. Veuillez réessayer.');
                        handleStopCamera();
                    });
                }
                updateCameraUI('streaming');
                logDebug('Webcam démarrée avec succès');
            })
            .catch(err => {
                handleCameraError(err);
            });
    }

    /**
     * Arrêter la capture vidéo webcam
     */
    function handleStopCamera() {
        if (state.videoStream) {
            state.videoStream.getTracks().forEach(track => track.stop());
            state.videoStream = null;
        }
        const videoElement = document.getElementById('cameraVideo');
        const cameraContainer = document.querySelector('.camera-container');
        if (videoElement) {
            videoElement.style.display = 'none';
        }
        if (cameraContainer) {
            cameraContainer.style.display = 'none';
        }
        updateCameraUI('idle');
        logDebug('Webcam arrêtée');
    }

    /**
     * Capturer une photo depuis le flux vidéo
     */
    function handleCapturePhoto() {
        const videoElement = document.getElementById('cameraVideo');
        if (!videoElement || !state.videoStream) {
            showError('La webcam n\'est pas active.');
            return;
        }

        try {
            state.isCapturing = true;
            
            const canvas = document.createElement('canvas');
            canvas.width = CONFIG.canvasWidth;
            canvas.height = CONFIG.canvasHeight;
            
            const ctx = canvas.getContext('2d');
            if (!ctx) {
                throw new Error('Impossible d\'obtenir le contexte canvas');
            }

            // Dessiner la vidéo sur le canvas
            ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
            
            // Convertir en blob
            canvas.toBlob(blob => {
                if (!blob) {
                    logError('Impossible de créer l\'image');
                    showError('Erreur lors de la capture. Veuillez réessayer.');
                    state.isCapturing = false;
                    return;
                }

                state.capturedPhoto = {
                    blob: blob,
                    url: URL.createObjectURL(blob),
                    timestamp: new Date().toISOString()
                };

                displayCapturedPhoto(state.capturedPhoto);
                updateCameraUI('captured');
                state.isCapturing = false;
                logDebug('Photo capturée avec succès');
            }, 'image/jpeg', 0.95);
        } catch (err) {
            logError('Erreur lors de la capture:', err);
            showError('Erreur lors de la capture photo. Veuillez réessayer.');
            state.isCapturing = false;
        }
    }

    /**
     * Reprendre une nouvelle photo
     */
    function handleRetakePhoto() {
        if (state.capturedPhoto && state.capturedPhoto.url) {
            URL.revokeObjectURL(state.capturedPhoto.url);
        }
        state.capturedPhoto = null;
        const previewElement = document.getElementById('photoPreview');
        if (previewElement) {
            previewElement.style.display = 'none';
        }
        updateCameraUI('streaming');
        logDebug('Réinitialisation pour nouvelle capture');
    }

    /**
     * Uploader la photo capturée vers l'API
     */
    function handleUploadPhoto() {
        if (!state.capturedPhoto) {
            showError('Aucune photo capturée.');
            return;
        }

        if (state.isUploading) {
            logWarn('Upload en cours...');
            return;
        }

        uploadPhoto();
    }

    /**
     * Effectuer l'upload de la photo
     */
    function uploadPhoto() {
        if (!state.capturedPhoto || !state.capturedPhoto.blob) {
            showError('Photo non disponible pour l\'upload.');
            return;
        }

        state.isUploading = true;
        state.uploadRetries = 0;
        updateCameraUI('uploading');
        showInfo('Upload en cours...');

        // Essayer d'abord les inputs cachés
        let demandeId = document.getElementById('photoWebcamDemandeId')?.value;
        let dossierId = document.getElementById('photoWebcamDossierId')?.value;

        // Fallback : récupérer depuis les data-* du bloc
        if (!demandeId || !dossierId) {
            const photoBlock = document.getElementById('photo-identite-block');
            if (photoBlock) {
                demandeId = demandeId || photoBlock.dataset.demandeId;
                dossierId = dossierId || photoBlock.dataset.dossierId;
                logDebug('Fallback data-*:', { demandeId, dossierId });
            }
        }

        // DEBUG: Afficher ce qu'on a trouvé
        logDebug('IDs trouvés:', { 
            demandeId, 
            dossierId,
            inputDemande: document.getElementById('photoWebcamDemandeId')?.value,
            inputDossier: document.getElementById('photoWebcamDossierId')?.value,
            blockExists: !!document.getElementById('photo-identite-block')
        });

        if (!demandeId || !dossierId) {
            showError('Identifiants de demande/dossier manquants. Vérifiez la console.');
            logError('Missing IDs:', {
                demandeId: demandeId || 'UNDEFINED',
                dossierId: dossierId || 'UNDEFINED',
                photoBlock: document.getElementById('photo-identite-block') ? 'exists' : 'NOT FOUND'
            });
            state.isUploading = false;
            updateCameraUI('captured');
            return;
        }

        const formData = new FormData();
        const filename = 'photo_identite_' + Date.now() + '.jpg';
        formData.append('file', state.capturedPhoto.blob, filename);
        formData.append('demandeId', demandeId);
        formData.append('dossierId', dossierId);

        const appRoot = getAppRoot();
        const basePath = appRoot ? '/' + appRoot : '';
        const url = basePath + `/demande/${demandeId}/dossiers/${dossierId}/photo-identite`;

        performUpload(url, formData, 0);
    }

    /**
     * Effectuer la requête d'upload avec gestion des tentatives
     */
    function performUpload(url, formData, retryCount) {
        fetch(url, {
            method: 'POST',
            body: formData,
            timeout: CONFIG.uploadTimeout
        })
        .then(response => {
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return response.json().then(data => ({
                    ok: response.ok,
                    status: response.status,
                    data: data
                }));
            } else {
                return response.text().then(text => ({
                    ok: response.ok,
                    status: response.status,
                    data: { message: text }
                }));
            }
        })
        .then(response => {
            if (response.ok) {
                handleUploadSuccess(response.data);
            } else {
                handleUploadError(response.data, url, formData, retryCount);
            }
        })
        .catch(err => {
            logError('Erreur réseau lors de l\'upload:', err);
            if (retryCount < CONFIG.maxRetries) {
                logWarn(`Tentative ${retryCount + 1}/${CONFIG.maxRetries} après erreur réseau`);
                setTimeout(() => {
                    performUpload(url, formData, retryCount + 1);
                }, 1000 * (retryCount + 1));
            } else {
                showError('Erreur lors de l\'upload. Veuillez réessayer.');
                state.isUploading = false;
                updateCameraUI('captured');
            }
        });
    }

    /**
     * Gérer le succès de l'upload
     */
    function handleUploadSuccess(response) {
        state.isUploading = false;
        logDebug('Upload réussi:', response);

        showSuccess('Photo d\'identité uploadée avec succès!');
        updateCameraUI('success');
        markPhotoPieceCardScanned(response.nomFichier || 'photo_identite.jpg', response.pieceRefId);

        // Notifier les autres modules de l'état du scan
        document.dispatchEvent(new CustomEvent('scan:pieceUploaded', {
            detail: {
                demandeComplete: response.demandeComplete,
                photoUploaded: response.photoUploaded,
                signatureUploaded: response.signatureUploaded
            }
        }));

        // Rafraîchir le résumé du scan après 1 seconde
        setTimeout(() => {
            refreshScanSummary();
        }, 1000);

        // Réinitialiser après 3 secondes
        setTimeout(() => {
            state.capturedPhoto = null;
            handleStopCamera();
            updateCameraUI('idle');
        }, 3000);
    }

    /**
     * Marquer la carte de photo d'identité comme scannée dans l'interface
     */
    function markPhotoPieceCardScanned(fileName, pieceRefId) {
        var card = null;

        if (pieceRefId) {
            card = document.getElementById('piece-' + pieceRefId);
        }

        if (!card) {
            var cards = document.querySelectorAll('.piece-card');
            for (var i = 0; i < cards.length; i++) {
                var label = cards[i].querySelector('.piece-card__label');
                if (!label || !label.textContent) continue;
                var text = label.textContent.toLowerCase();
                if (text.indexOf('photo') !== -1 && text.indexOf('identit') !== -1) {
                    card = cards[i];
                    break;
                }
            }
        }

        if (!card) {
            return;
        }

        card.classList.add('piece-card--done');

        var checkbox = card.querySelector('.js-piece-checkbox');
        if (checkbox) {
            checkbox.checked = true;
            checkbox.dataset.serverScanned = '1';
        }

        var dot = card.querySelector('.piece-card__status-dot');
        if (dot) {
            dot.classList.remove('dot--gray');
            dot.classList.add('dot--green');
        }

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

        var chosen = card.querySelector('.piece-card__file-chosen');
        if (chosen) {
            chosen.textContent = fileName;
        }

        var uploadBtn = card.querySelector('.js-upload-btn');
        if (uploadBtn) {
            uploadBtn.textContent = 'Uploadé';
            uploadBtn.disabled = true;
        }
    }

    /**
     * Gérer les erreurs d'upload
     */
    function handleUploadError(response, url, formData, retryCount) {
        const errorMsg = response.message || response.error || 'Erreur lors de l\'upload';
        logError('Erreur d\'upload:', errorMsg);

        if (retryCount < CONFIG.maxRetries) {
            logWarn(`Tentative ${retryCount + 1}/${CONFIG.maxRetries}`);
            setTimeout(() => {
                performUpload(url, formData, retryCount + 1);
            }, 1000 * (retryCount + 1));
        } else {
            state.isUploading = false;
            showError(errorMsg || 'Erreur lors de l\'upload photo. Veuillez réessayer.');
            updateCameraUI('captured');
        }
    }

    /**
     * Gérer les erreurs d'accès à la webcam
     */
    function handleCameraError(err) {
        state.videoStream = null;
        updateCameraUI('idle');

        let errorMsg = 'Erreur d\'accès à la webcam';
        
        if (err.name === 'NotAllowedError') {
            errorMsg = 'Accès à la webcam refusé. Veuillez autoriser l\'accès dans les paramètres du navigateur.';
        } else if (err.name === 'NotFoundError') {
            errorMsg = 'Aucune webcam détectée sur cet appareil.';
        } else if (err.name === 'NotReadableError') {
            errorMsg = 'La webcam est déjà utilisée par une autre application.';
        }

        logError('Erreur camera:', err.name, err.message);
        showError(errorMsg);
    }

    /**
     * Afficher la photo capturée dans le DOM
     */
    function displayCapturedPhoto(photo) {
        const previewElement = document.getElementById('photoPreview');
        if (previewElement) {
            previewElement.src = photo.url;
            previewElement.style.display = 'block';
        }
    }

    /**
     * Mettre à jour l'interface selon l'état
     */
    function updateCameraUI(state) {
        const startBtn = document.getElementById('startCameraBtn');
        const stopBtn = document.getElementById('stopCameraBtn');
        const captureBtn = document.getElementById('capturePhotoBtn');
        const retakeBtn = document.getElementById('retakeCameraBtn');
        const uploadBtn = document.getElementById('uploadPhotoBtn');
        const statusDiv = document.getElementById('photoUploadStatus');
        const cameraContainer = document.querySelector('.camera-container');
        const previewElement = document.getElementById('photoPreview');

        // Réinitialiser tous les boutons
        [startBtn, stopBtn, captureBtn, retakeBtn, uploadBtn].forEach(btn => {
            if (btn) btn.disabled = false;
        });

        switch (state) {
            case 'idle':
                if (startBtn) startBtn.style.display = 'inline-block';
                if (stopBtn) stopBtn.style.display = 'none';
                if (captureBtn) captureBtn.style.display = 'none';
                if (retakeBtn) retakeBtn.style.display = 'none';
                if (uploadBtn) uploadBtn.style.display = 'none';
                if (cameraContainer) cameraContainer.style.display = 'none';
                if (previewElement) previewElement.style.display = 'none';
                if (statusDiv) {
                    statusDiv.innerHTML = '';
                    statusDiv.style.display = 'none';
                }
                break;
            case 'streaming':
                if (startBtn) startBtn.style.display = 'none';
                if (stopBtn) stopBtn.style.display = 'inline-block';
                if (captureBtn) captureBtn.style.display = 'inline-block';
                if (retakeBtn) retakeBtn.style.display = 'none';
                if (uploadBtn) uploadBtn.style.display = 'none';
                if (cameraContainer) cameraContainer.style.display = 'block';
                if (previewElement) previewElement.style.display = 'none';
                if (statusDiv) {
                    statusDiv.innerHTML = '';
                    statusDiv.style.display = 'none';
                }
                break;
            case 'captured':
                if (startBtn) startBtn.style.display = 'none';
                if (stopBtn) stopBtn.style.display = 'inline-block';
                if (captureBtn) captureBtn.disabled = true;
                if (captureBtn) captureBtn.style.display = 'inline-block';
                if (retakeBtn) retakeBtn.style.display = 'inline-block';
                if (uploadBtn) uploadBtn.style.display = 'inline-block';
                if (cameraContainer) cameraContainer.style.display = 'block';
                break;
            case 'uploading':
                [startBtn, stopBtn, captureBtn, retakeBtn, uploadBtn].forEach(btn => {
                    if (btn) btn.disabled = true;
                });
                if (statusDiv) {
                    statusDiv.innerHTML = '<span class="info">Upload en cours...</span>';
                    statusDiv.style.display = 'block';
                }
                break;
            case 'success':
                if (statusDiv) statusDiv.innerHTML = '<span class="success">✓ Photo uploadée avec succès</span>';
                [startBtn, stopBtn, captureBtn, retakeBtn, uploadBtn].forEach(btn => {
                    if (btn) btn.disabled = true;
                });
                break;
        }
    }

    /**
     * Rafraîchir le résumé du scan
     */
    function refreshScanSummary() {
        const demandeId = document.getElementById('photoWebcamDemandeId')?.value;
        if (!demandeId) return;

        const appRoot = getAppRoot();
        const basePath = appRoot ? '/' + appRoot : '';
        const url = basePath + '/demande/' + demandeId + '/scan-status?demandeId=' + encodeURIComponent(demandeId);

        fetch(url, { cache: 'no-store' })
            .then(response => response.json())
            .then(data => {
                logDebug('Statut du scan rafraîchi:', data);
                // Émettre un événement custom pour notifier d'autres modules
                window.dispatchEvent(new CustomEvent('scanStatusUpdated', {
                    detail: data
                }));
            })
            .catch(err => {
                logWarn('Erreur lors du rafraîchissement du statut:', err);
            });
    }

    /**
     * Afficher un message de succès
     */
    function showSuccess(msg) {
        const statusDiv = document.getElementById('photoUploadStatus');
        if (statusDiv) {
            statusDiv.innerHTML = '<span class="success">✓ ' + msg + '</span>';
            statusDiv.style.color = 'green';
            statusDiv.style.display = 'block';
        }
        logDebug('Succès:', msg);
    }

    /**
     * Afficher un message d'erreur
     */
    function showError(msg) {
        const statusDiv = document.getElementById('photoUploadStatus');
        if (statusDiv) {
            statusDiv.innerHTML = '<span class="error">✗ ' + msg + '</span>';
            statusDiv.style.color = 'red';
            statusDiv.style.display = 'block';
        }
        logError('Erreur:', msg);
    }

    /**
     * Afficher un message d'info
     */
    function showInfo(msg) {
        const statusDiv = document.getElementById('photoUploadStatus');
        if (statusDiv) {
            statusDiv.innerHTML = '<span class="info">ℹ ' + msg + '</span>';
            statusDiv.style.color = 'blue';
            statusDiv.style.display = 'block';
        }
        logDebug('Info:', msg);
    }

    /**
     * Logging debug
     */
    function logDebug(msg, ...args) {
        if (window.debugMode) {
            console.log('[PhotoWebcam]', msg, ...args);
        }
    }

    /**
     * Logging warning
     */
    function logWarn(msg, ...args) {
        console.warn('[PhotoWebcam]', msg, ...args);
    }

    /**
     * Logging error
     */
    function logError(msg, ...args) {
        console.error('[PhotoWebcam]', msg, ...args);
    }

    /**
     * Nettoyage à la fermeture de la page
     */
    function cleanup() {
        handleStopCamera();
        if (state.capturedPhoto && state.capturedPhoto.url) {
            URL.revokeObjectURL(state.capturedPhoto.url);
        }
    }

    // Initialisation au chargement du DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Nettoyage à la fermeture
    window.addEventListener('beforeunload', cleanup);

    // Exporter les fonctions principales pour test/debug
    window.PhotoWebcam = {
        init: init,
        startCamera: handleStartCamera,
        stopCamera: handleStopCamera,
        capturePhoto: handleCapturePhoto,
        uploadPhoto: handleUploadPhoto,
        cleanup: cleanup
    };

})();