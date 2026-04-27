(function () {
    function byId(id) {
        return document.getElementById(id);
    }

    function textValue(id) {
        const el = byId(id);
        if (!el) return '-';

        if (el.tagName === 'SELECT') {
            if (!el.selectedOptions || !el.selectedOptions.length) return '-';
            const label = (el.selectedOptions[0].textContent || '').trim();
            return label || '-';
        }

        const value = (el.value || '').toString().trim();
        return value || '-';
    }

    function checkedRadioValue(name) {
        const checked = document.querySelector('input[name="' + name + '"]:checked');
        return checked ? checked.value : '-';
    }

    function fillList(targetId, rows) {
        const target = byId(targetId);
        if (!target) return;
        target.innerHTML = rows.map(function (row) {
            return '<li><strong>' + row.label + ':</strong> ' + row.value + '</li>';
        }).join('');
    }

    function getCheckedPieces() {
        const checked = Array.from(document.querySelectorAll('input[type="checkbox"][name="piece_ids"]:checked'));
        return checked.map(function (input) {
            const item = input.closest('.checkbox-item');
            if (!item) return null;
            const label = item.querySelector('label');
            if (!label) return null;
            return (label.textContent || '').replace('*', '').trim();
        }).filter(Boolean);
    }

    function fillPieces() {
        const target = byId('recapPieces');
        if (!target) return;

        const pieces = getCheckedPieces();
        if (!pieces.length) {
            target.innerHTML = '<li>Aucune piece selectionnee</li>';
            return;
        }

        target.innerHTML = pieces.map(function (piece) {
            return '<li>' + piece + '</li>';
        }).join('');
    }

    function buildRecap() {
        fillList('recapDemandeur', [
            { label: 'Nom', value: textValue('nom') },
            { label: 'Prenom', value: textValue('prenom') },
            { label: 'Date de naissance', value: textValue('dateNaissance') },
            { label: 'Situation familiale', value: textValue('situationFamille') },
            { label: 'Nationalite', value: textValue('nationalite') },
            { label: 'Adresse', value: textValue('adresseMadagascar') },
            { label: 'Telephone', value: textValue('numeroTelephone') },
            { label: 'Email', value: textValue('email') },
            { label: 'Profession', value: textValue('profession') }
        ]);

        fillList('recapDemande', [
            { label: 'Type de demande', value: textValue('typeDemande') },
            { label: 'Profil', value: checkedRadioValue('profil') },
            { label: 'Numero passeport', value: textValue('numeroPasseport') },
            { label: 'Date delivrance', value: textValue('dateDelivrance') },
            { label: 'Date expiration', value: textValue('dateExpiration') },
            { label: 'Pays delivrance', value: textValue('paysDelivrance') },
            { label: 'Date entree visa', value: textValue('visaDateEntree') },
            { label: 'Lieu entree visa', value: textValue('visaLieuEntree') },
            { label: 'Date expiration visa', value: textValue('visaDateExpiration') },
            { label: 'Categorie', value: textValue('categorieDemande') }
        ]);

        fillPieces();
    }

    function toggleRecap(show) {
        const recapSection = byId('recapSection');
        if (!recapSection) return;
        recapSection.classList.toggle('hidden', !show);

        if (show) {
            recapSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }

    window.addEventListener('DOMContentLoaded', function () {
        const form = byId('demandeForm');
        const reviewBtn = byId('reviewBtn');
        const backBtn = byId('backToEditBtn');
        const confirmBtn = byId('confirmSubmitBtn');

        if (!form || !reviewBtn || !confirmBtn || !backBtn) return;

        reviewBtn.addEventListener('click', function () {
            window.__reviewAttempted = true;
            const valid = typeof validateForm === 'function' ? validateForm() : true;
            if (!valid) return;

            buildRecap();
            toggleRecap(true);
        });

        backBtn.addEventListener('click', function () {
            toggleRecap(false);
            reviewBtn.scrollIntoView({ behavior: 'smooth', block: 'center' });
        });

        confirmBtn.addEventListener('click', function () {
            window.__reviewAttempted = true;
            const valid = typeof validateForm === 'function' ? validateForm() : true;
            if (!valid) {
                toggleRecap(false);
                return;
            }
            form.requestSubmit();
        });
    });
})();
