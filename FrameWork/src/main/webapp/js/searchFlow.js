(function () {
    let lastFetchedSnapshot = null;

    function byId(id) {
        return document.getElementById(id);
    }

    function normalize(value) {
        return (value || '').toString().trim().toLowerCase();
    }

    function fillList(target, rows) {
        if (!target) return;
        target.innerHTML = rows.map(function (row) {
            return '<li><strong>' + row.label + ':</strong> ' + (row.value || '-') + '</li>';
        }).join('');
    }

    function showSearchResult(found, snapshot) {
        const foundBox = byId('searchFound');
        const notFoundBox = byId('searchNotFound');
        const statusText = byId('searchStatusText');

        if (foundBox) foundBox.classList.toggle('hidden', !found);
        if (notFoundBox) notFoundBox.classList.toggle('hidden', found);

        if (statusText) {
            statusText.textContent = found
                ? 'Resultat trouve dans la base de donnees.'
                : 'Aucun resultat trouve. Continuez avec la creation d un nouveau dossier.';
            statusText.style.color = found ? 'green' : 'red';
        }

        if (found && snapshot) {
            lastFetchedSnapshot = snapshot;
            fillList(byId('foundDemandeurInfo'), [
                { label: 'Nom', value: snapshot.nom },
                { label: 'Prenom', value: snapshot.prenom },
                { label: 'Date de naissance', value: snapshot.dateNaissance },
                { label: 'Nationalite', value: snapshot.nationalite },
                { label: 'Adresse', value: snapshot.adresseMadagascar },
                { label: 'Telephone', value: snapshot.numeroTelephone },
                { label: 'Email', value: snapshot.email },
                { label: 'Profession', value: snapshot.profession }
            ]);

            fillList(byId('foundPasseportInfo'), [
                { label: 'Numero', value: snapshot.numeroPasseport },
                { label: 'Date delivrance', value: snapshot.dateDelivrance },
                { label: 'Date expiration', value: snapshot.dateExpiration },
                { label: 'Pays', value: snapshot.paysDelivrance }
            ]);
        } else {
            lastFetchedSnapshot = null;
        }
    }

    function runSearch() {
        const nom = byId('searchNom') ? byId('searchNom').value.trim() : '';
        const prenom = byId('searchPrenom') ? byId('searchPrenom').value.trim() : '';
        const dateNaissance = byId('searchDateNaissance') ? byId('searchDateNaissance').value.trim() : '';
        const numeroPasseport = byId('searchNumeroPasseport') ? byId('searchNumeroPasseport').value.trim() : '';

        const hasIdentity = nom || prenom || dateNaissance;
        const hasPassport = numeroPasseport;

        if (!hasIdentity && !hasPassport) {
            const statusText = byId('searchStatusText');
            if (statusText) {
                statusText.textContent = 'Veuillez renseigner au moins un critere de recherche.';
                statusText.style.color = 'red';
            }
            return;
        }

        const formData = new FormData();
        if (nom) formData.append('nom', nom);
        if (prenom) formData.append('prenom', prenom);
        if (dateNaissance) formData.append('dateNaissance', dateNaissance);
        if (numeroPasseport) formData.append('numeroPasseport', numeroPasseport);

        const statusText = byId('searchStatusText');
        if (statusText) {
            statusText.textContent = 'Recherche en cours...';
            statusText.style.color = 'blue';
        }

        fetch('form/search', {
            method: 'POST',
            body: formData
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Erreur reseau');
            }
            return response.json();
        })
        .then(data => {
            const payload = data && data.data ? data.data : data;
            const found = !!(payload && payload.found);
            const snapshot = found
                ? (payload.data || payload.demandeur || payload.result || payload)
                : null;

            if (payload && payload.message) {
                const statusText = byId('searchStatusText');
                if (statusText) {
                    statusText.textContent = payload.message;
                    statusText.style.color = found ? 'green' : 'red';
                }
            }

            showSearchResult(found, snapshot);
        })
        .catch(error => {
            console.error('Erreur lors de la recherche:', error);
            if (statusText) {
                statusText.textContent = 'Recherche indisponible pour le moment.';
                statusText.style.color = 'red';
            }
            showSearchResult(false, null);
        });
    }

    function applySnapshotToForm() {
        const snapshot = lastFetchedSnapshot;
        if (!snapshot) return;

        const mapping = {
            nom: 'nom',
            prenom: 'prenom',
            dateNaissance: 'dateNaissance',
            adresseMadagascar: 'adresseMadagascar',
            numeroTelephone: 'numeroTelephone',
            email: 'email',
            profession: 'profession',
            numeroPasseport: 'numeroPasseport',
            dateDelivrance: 'dateDelivrance',
            dateExpiration: 'dateExpiration',
            paysDelivrance: 'paysDelivrance'
        };

        Object.keys(mapping).forEach(function (sourceKey) {
            const target = byId(mapping[sourceKey]);
            if (target && snapshot[sourceKey] != null) {
                target.value = snapshot[sourceKey];
                target.dispatchEvent(new Event('input', { bubbles: true }));
                target.dispatchEvent(new Event('change', { bubbles: true }));
            }
        });

        // Set select matching options 
        if (snapshot.nationalite) {
            const natSelect = byId('nationalite');
            if (natSelect) {
                Array.from(natSelect.options).forEach(opt => {
                    if (opt.text.toLowerCase() === snapshot.nationalite.toLowerCase()) {
                        natSelect.value = opt.value;
                    }
                });
            }
        }
    }

    function loadTypeDemandeOptions() {
        const fromType = byId('typeDemande');
        const target = byId('nextTypeDemande');
        if (!fromType || !target) return;

        target.innerHTML = '';
        Array.from(fromType.options).forEach(function (option) {
            if (!option.value) return;
            const clone = option.cloneNode(true);
            target.appendChild(clone);
        });
    }

    function applySelectedType() {
        const from = byId('nextTypeDemande');
        const to = byId('typeDemande');
        if (!from || !to || !from.value) return;

        to.value = from.value;
        to.dispatchEvent(new Event('change', { bubbles: true }));
    }

    window.addEventListener('DOMContentLoaded', function () {
        const searchButton = byId('runRechercheBtn');
        const useFoundDataBtn = byId('useFoundDataBtn');
        const applyNextTypeBtn = byId('applyNextTypeBtn');

        loadTypeDemandeOptions();

        if (searchButton) {
            searchButton.addEventListener('click', runSearch);
        }

        if (useFoundDataBtn) {
            useFoundDataBtn.addEventListener('click', applySnapshotToForm);
        }

        if (applyNextTypeBtn) {
            applyNextTypeBtn.addEventListener('click', applySelectedType);
        }
    });
})();
