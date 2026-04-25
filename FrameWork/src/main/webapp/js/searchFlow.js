(function () {
    const STORAGE_KEY = 'visa_last_demandeur';

    function byId(id) {
        return document.getElementById(id);
    }

    function normalize(value) {
        return (value || '').toString().trim().toLowerCase();
    }

    function getFormSnapshot() {
        return {
            nom: byId('nom') ? byId('nom').value.trim() : '',
            prenom: byId('prenom') ? byId('prenom').value.trim() : '',
            dateNaissance: byId('dateNaissance') ? byId('dateNaissance').value : '',
            nationalite: byId('nationalite') && byId('nationalite').selectedOptions.length
                ? byId('nationalite').selectedOptions[0].textContent.trim()
                : '',
            adresse: byId('adresseMadagascar') ? byId('adresseMadagascar').value.trim() : '',
            telephone: byId('numeroTelephone') ? byId('numeroTelephone').value.trim() : '',
            email: byId('email') ? byId('email').value.trim() : '',
            profession: byId('profession') ? byId('profession').value.trim() : '',
            numeroPasseport: byId('numeroPasseport') ? byId('numeroPasseport').value.trim() : '',
            dateDelivrance: byId('dateDelivrance') ? byId('dateDelivrance').value : '',
            dateExpiration: byId('dateExpiration') ? byId('dateExpiration').value : '',
            paysDelivrance: byId('paysDelivrance') ? byId('paysDelivrance').value.trim() : ''
        };
    }

    function saveSnapshotIfRelevant() {
        const snapshot = getFormSnapshot();
        if (!snapshot.nom || !snapshot.dateNaissance || !snapshot.numeroPasseport) {
            return;
        }

        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot));
        } catch (e) {
            // Ignore localStorage errors (private mode, quota)
        }
    }

    function loadSnapshot() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : null;
        } catch (e) {
            return null;
        }
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
                ? 'Resultat trouve dans les dernieres donnees locales du navigateur.'
                : 'Aucun resultat local. Continuez avec la creation d un nouveau dossier.';
        }

        if (found && snapshot) {
            fillList(byId('foundDemandeurInfo'), [
                { label: 'Nom', value: snapshot.nom },
                { label: 'Prenom', value: snapshot.prenom },
                { label: 'Date de naissance', value: snapshot.dateNaissance },
                { label: 'Nationalite', value: snapshot.nationalite },
                { label: 'Adresse', value: snapshot.adresse },
                { label: 'Telephone', value: snapshot.telephone },
                { label: 'Email', value: snapshot.email },
                { label: 'Profession', value: snapshot.profession }
            ]);

            fillList(byId('foundPasseportInfo'), [
                { label: 'Numero', value: snapshot.numeroPasseport },
                { label: 'Date delivrance', value: snapshot.dateDelivrance },
                { label: 'Date expiration', value: snapshot.dateExpiration },
                { label: 'Pays', value: snapshot.paysDelivrance }
            ]);
        }
    }

    function runLocalSearch() {
        const query = {
            nom: normalize(byId('searchNom') ? byId('searchNom').value : ''),
            prenom: normalize(byId('searchPrenom') ? byId('searchPrenom').value : ''),
            dateNaissance: normalize(byId('searchDateNaissance') ? byId('searchDateNaissance').value : ''),
            numeroPasseport: normalize(byId('searchNumeroPasseport') ? byId('searchNumeroPasseport').value : '')
        };

        const snapshot = loadSnapshot();
        if (!snapshot) {
            showSearchResult(false, null);
            return;
        }

        const hasIdentity = query.nom || query.prenom || query.dateNaissance;
        const hasPassport = query.numeroPasseport;
        if (!hasIdentity && !hasPassport) {
            const statusText = byId('searchStatusText');
            if (statusText) {
                statusText.textContent = 'Veuillez renseigner au moins un critere de recherche.';
            }
            return;
        }

        const matchPassport = hasPassport && query.numeroPasseport === normalize(snapshot.numeroPasseport);
        const matchIdentity = hasIdentity
            && (!query.nom || query.nom === normalize(snapshot.nom))
            && (!query.prenom || query.prenom === normalize(snapshot.prenom))
            && (!query.dateNaissance || query.dateNaissance === normalize(snapshot.dateNaissance));

        const found = matchPassport || matchIdentity;
        showSearchResult(found, found ? snapshot : null);
    }

    function applySnapshotToForm() {
        const snapshot = loadSnapshot();
        if (!snapshot) return;

        const mapping = {
            nom: 'nom',
            prenom: 'prenom',
            dateNaissance: 'dateNaissance',
            adresse: 'adresseMadagascar',
            telephone: 'numeroTelephone',
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
        const form = byId('demandeForm');

        loadTypeDemandeOptions();

        if (searchButton) {
            searchButton.addEventListener('click', runLocalSearch);
        }

        if (useFoundDataBtn) {
            useFoundDataBtn.addEventListener('click', applySnapshotToForm);
        }

        if (applyNextTypeBtn) {
            applyNextTypeBtn.addEventListener('click', applySelectedType);
        }

        if (form) {
            form.addEventListener('submit', saveSnapshotIfRelevant);
        }
    });
})();
