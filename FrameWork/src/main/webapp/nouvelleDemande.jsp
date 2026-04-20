<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>
<%@ page import="models.PieceJustificative" %>
<%@ page import="models.TypeTitre" %>
<%!
    String value(Map<String, Object> data, String key) {
        if (data == null || key == null) {
            return "";
        }
        Object raw = data.get(key);
        if (raw == null) {
            return "";
        }
        if (raw instanceof String[]) {
            String[] arr = (String[]) raw;
            return arr.length > 0 ? arr[0] : "";
        }
        return String.valueOf(raw);
    }

    boolean isChecked(Map<String, Object> data, long id) {
        if (data == null) {
            return false;
        }
        Object raw = data.get("piece_ids");
        if (raw == null) {
            raw = data.get("piece_id");
        }
        if (raw == null) {
            return false;
        }

        String needle = String.valueOf(id);

        if (raw instanceof String[]) {
            String[] arr = (String[]) raw;
            for (String s : arr) {
                if (needle.equals(String.valueOf(s).trim())) {
                    return true;
                }
            }
            return false;
        }

        String one = String.valueOf(raw).trim();
        if (one.contains(",")) {
            String[] arr = one.split(",");
            for (String s : arr) {
                if (needle.equals(String.valueOf(s).trim())) {
                    return true;
                }
            }
            return false;
        }

        return needle.equals(one);
    }
%>
<%
    String cp = request.getContextPath();
    Map<String, Object> formData = (Map<String, Object>) request.getAttribute("formData");
    List<TypeTitre> typeTitreOptions = (List<TypeTitre>) request.getAttribute("typeTitreOptions");
    List<PieceJustificative> piecesCommunes = (List<PieceJustificative>) request.getAttribute("piecesCommunes");
    List<PieceJustificative> piecesInvestisseur = (List<PieceJustificative>) request.getAttribute("piecesInvestisseur");
    List<PieceJustificative> piecesTravailleur = (List<PieceJustificative>) request.getAttribute("piecesTravailleur");

    String message = (String) request.getAttribute("message");

    String selectedTypeTitre = value(formData, "type_titre_id");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Nouvelle demande de visa</title>
    <style>
        :root {
            --bg-start: #f7f0e6;
            --bg-end: #efe3d3;
            --panel: #fffdf8;
            --ink: #25201a;
            --muted: #74685a;
            --accent: #0f766e;
            --accent-2: #8a5a44;
            --danger: #b42318;
            --line: #dbcab4;
            --shadow: 0 14px 34px rgba(46, 33, 18, 0.12);
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: "Trebuchet MS", "Segoe UI", sans-serif;
            color: var(--ink);
            background:
                radial-gradient(circle at 10% 15%, rgba(15, 118, 110, 0.12), transparent 45%),
                radial-gradient(circle at 90% 80%, rgba(138, 90, 68, 0.14), transparent 40%),
                linear-gradient(160deg, var(--bg-start), var(--bg-end));
            min-height: 100vh;
        }

        .page {
            max-width: 1080px;
            margin: 26px auto;
            padding: 0 16px 30px;
        }

        .hero {
            background: linear-gradient(130deg, #164e63, #0f766e 55%, #8a5a44);
            color: #fff;
            border-radius: 18px;
            padding: 22px;
            box-shadow: var(--shadow);
            animation: pop-in 420ms ease-out;
        }

        .hero h1 {
            margin: 0;
            font-size: 1.9rem;
            letter-spacing: 0.3px;
        }

        .hero p {
            margin: 8px 0 0;
            opacity: 0.95;
        }

        .notice {
            margin-top: 14px;
            border-radius: 10px;
            padding: 10px 12px;
            background: #ecfeff;
            border: 1px solid #a5f3fc;
            color: #134e4a;
        }

        .card {
            margin-top: 18px;
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 16px;
            box-shadow: var(--shadow);
            overflow: hidden;
        }

        .section {
            padding: 18px 18px 8px;
            border-bottom: 1px dashed var(--line);
            animation: rise 360ms ease both;
        }

        .section:last-child {
            border-bottom: 0;
            padding-bottom: 18px;
        }

        .section h2 {
            margin: 0 0 12px;
            font-size: 1.12rem;
            color: var(--accent-2);
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 12px;
        }

        .field {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .field label {
            font-size: 0.9rem;
            color: var(--muted);
        }

        .required::after {
            content: " *";
            color: var(--danger);
            font-weight: 700;
        }

        .field input,
        .field select,
        .field textarea {
            border: 1px solid #d6c3aa;
            border-radius: 9px;
            padding: 10px;
            background: #fff;
            color: var(--ink);
            font-size: 0.95rem;
        }

        .field textarea {
            min-height: 76px;
            resize: vertical;
        }

        .wide {
            grid-column: span 2;
        }

        .full {
            grid-column: 1 / -1;
        }

        .pieces-wrap {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }

        .piece-box {
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 10px;
            background: #fff;
        }

        .piece-box h3 {
            margin: 0 0 8px;
            font-size: 0.95rem;
            color: #0f766e;
        }

        .piece-list {
            display: grid;
            gap: 8px;
            max-height: 240px;
            overflow: auto;
            padding-right: 4px;
        }

        .piece-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 0.92rem;
            color: #364152;
        }

        .piece-specific {
            display: none;
        }

        .actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            margin-top: 10px;
        }

        .hint {
            font-size: 0.84rem;
            color: var(--muted);
        }

        .btns {
            display: flex;
            gap: 10px;
        }

        .btn {
            border: 0;
            border-radius: 10px;
            padding: 10px 14px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
            color: #fff;
            transition: transform 180ms ease, filter 180ms ease;
        }

        .btn:hover {
            transform: translateY(-1px);
            filter: brightness(1.03);
        }

        .btn:disabled {
            opacity: 0.58;
            cursor: not-allowed;
            transform: none;
            filter: none;
        }

        .btn-validate {
            background: #0f766e;
        }

        .btn-save {
            background: #8a5a44;
        }

        .btn-update {
            background: #3f6212;
        }

        .btn-back {
            background: #475467;
        }

        @media (max-width: 900px) {
            .grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
            .pieces-wrap {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 640px) {
            .grid {
                grid-template-columns: 1fr;
            }
            .wide,
            .full {
                grid-column: auto;
            }
            .actions {
                flex-direction: column;
                align-items: stretch;
            }
            .btns {
                width: 100%;
                display: grid;
                grid-template-columns: 1fr;
            }
        }

        @keyframes pop-in {
            from {
                opacity: 0;
                transform: translateY(6px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        @keyframes rise {
            from {
                opacity: 0;
                transform: translateY(6px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    </style>
</head>
<body>
<div class="page">
    <div class="hero">
        <h1>Demande de visa transformable</h1>
        <p>Sprint 1: profil investisseur ou travailleur, type de demande principal: Nouveau titre.</p>
    </div>

    <% if (message != null && !message.isEmpty()) { %>
        <div class="notice"><%= message %></div>
    <% } %>

    <div class="card">
        <form id="visaForm" action="<%= cp %>/visa/form" method="post">
            <div class="section">
                <h2>Type de demande</h2>
                <div class="grid">
                    <div class="field">
                        <label class="required" for="type_demande_id">Categorie de demande</label>
                        <select id="type_demande_id" name="type_demande_id" required>
                            <option value="">-- Choisir --</option>
                            <option value="1" <%= "1".equals(value(formData, "type_demande_id")) ? "selected" : "" %>>Nouveau titre</option>
                            <option value="2" disabled>Duplicata (Sprint futur)</option>
                            <option value="3" disabled>Transfert de visa (Sprint futur)</option>
                        </select>
                    </div>

                    <div class="field">
                        <label class="required" for="type_titre_id">Profil</label>
                        <select id="type_titre_id" name="type_titre_id" required>
                            <option value="">-- Choisir --</option>
                            <% if (typeTitreOptions != null) {
                                for (TypeTitre t : typeTitreOptions) { %>
                                    <option value="<%= t.getId() %>" <%= String.valueOf(t.getId()).equals(selectedTypeTitre) ? "selected" : "" %>><%= t.getLibelle() %></option>
                            <%  }
                            } %>
                        </select>
                    </div>

                    <div class="field">
                        <label class="required" for="passeport_id">Passeport ID (test local)</label>
                        <input id="passeport_id" name="passeport_id" type="number" min="1" value="<%= value(formData, "passeport_id") %>" required />
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Etat civil</h2>
                <div class="grid">
                    <div class="field">
                        <label class="required" for="nom">Nom</label>
                        <input id="nom" name="nom" value="<%= value(formData, "nom") %>" required />
                    </div>
                    <div class="field">
                        <label for="prenom">Prenom</label>
                        <input id="prenom" name="prenom" value="<%= value(formData, "prenom") %>" />
                    </div>
                    <div class="field">
                        <label class="required" for="nom_jeune_fille">Nom de jeune fille</label>
                        <input id="nom_jeune_fille" name="nom_jeune_fille" value="<%= value(formData, "nom_jeune_fille") %>" required />
                    </div>

                    <div class="field">
                        <label class="required" for="date_naissance">Date de naissance</label>
                        <input id="date_naissance" name="date_naissance" type="date" value="<%= value(formData, "date_naissance") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="situation_famille_id">Situation de famille (id)</label>
                        <input id="situation_famille_id" name="situation_famille_id" type="number" min="1" value="<%= value(formData, "situation_famille_id") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="nationalite_id">Nationalite (id)</label>
                        <input id="nationalite_id" name="nationalite_id" type="number" min="1" value="<%= value(formData, "nationalite_id") %>" required />
                    </div>

                    <div class="field wide">
                        <label class="required" for="adresse_madagascar">Adresse Madagascar</label>
                        <textarea id="adresse_madagascar" name="adresse_madagascar" required><%= value(formData, "adresse_madagascar") %></textarea>
                    </div>
                    <div class="field">
                        <label class="required" for="numero_telephone">Numero telephone</label>
                        <input id="numero_telephone" name="numero_telephone" value="<%= value(formData, "numero_telephone") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="profession">Profession</label>
                        <input id="profession" name="profession" value="<%= value(formData, "profession") %>" required />
                    </div>
                    <div class="field">
                        <label for="email">Email</label>
                        <input id="email" name="email" type="email" value="<%= value(formData, "email") %>" />
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Passeport</h2>
                <div class="grid">
                    <div class="field">
                        <label class="required" for="numero_passeport">Numero passeport</label>
                        <input id="numero_passeport" name="numero_passeport" value="<%= value(formData, "numero_passeport") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="date_delivrance">Date de delivrance</label>
                        <input id="date_delivrance" name="date_delivrance" type="date" value="<%= value(formData, "date_delivrance") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="date_expiration">Date d'expiration</label>
                        <input id="date_expiration" name="date_expiration" type="date" value="<%= value(formData, "date_expiration") %>" required />
                    </div>
                    <div class="field wide">
                        <label class="required" for="pays_delivrance">Pays de delivrance</label>
                        <input id="pays_delivrance" name="pays_delivrance" value="<%= value(formData, "pays_delivrance") %>" required />
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Visa</h2>
                <div class="grid">
                    <div class="field">
                        <label class="required" for="visa_date_entree">Date d'entree</label>
                        <input id="visa_date_entree" name="visa_date_entree" type="date" value="<%= value(formData, "visa_date_entree") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="visa_lieu_entree">Lieu d'entree</label>
                        <input id="visa_lieu_entree" name="visa_lieu_entree" value="<%= value(formData, "visa_lieu_entree") %>" required />
                    </div>
                    <div class="field">
                        <label class="required" for="visa_date_expiration">Date d'expiration</label>
                        <input id="visa_date_expiration" name="visa_date_expiration" type="date" value="<%= value(formData, "visa_date_expiration") %>" required />
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Pieces justificatives</h2>
                <div class="pieces-wrap">
                    <div class="piece-box">
                        <h3>Pieces communes</h3>
                        <div class="piece-list">
                            <% if (piecesCommunes != null) {
                                for (PieceJustificative p : piecesCommunes) { %>
                                    <label class="piece-item">
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %> />
                                        <span><%= p.getLibelle() %></span>
                                    </label>
                            <%  }
                            } %>
                        </div>
                    </div>

                    <div class="piece-box piece-specific" id="box-investisseur">
                        <h3>Pieces investisseur</h3>
                        <div class="piece-list">
                            <% if (piecesInvestisseur != null) {
                                for (PieceJustificative p : piecesInvestisseur) { %>
                                    <label class="piece-item">
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %> />
                                        <span><%= p.getLibelle() %></span>
                                    </label>
                            <%  }
                            } %>
                        </div>
                    </div>

                    <div class="piece-box piece-specific" id="box-travailleur">
                        <h3>Pieces travailleur</h3>
                        <div class="piece-list">
                            <% if (piecesTravailleur != null) {
                                for (PieceJustificative p : piecesTravailleur) { %>
                                    <label class="piece-item">
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %> />
                                        <span><%= p.getLibelle() %></span>
                                    </label>
                            <%  }
                            } %>
                        </div>
                    </div>
                </div>

                <div class="actions">
                    <div class="hint">Les champs marques * sont obligatoires. Soumettre est active uniquement si le minimum est complet.</div>
                    <div class="btns">
                        <button id="validateBtn" class="btn btn-validate" type="submit" formaction="<%= cp %>/visa/form">Soumettre</button>
                        <button id="saveBtn" class="btn btn-save" type="submit" formaction="<%= cp %>/visa/form/save" disabled>Enregistrer</button>
                        <button class="btn btn-update" type="submit" formaction="<%= cp %>/visa/form/update">Mettre a jour</button>
                        <a class="btn btn-back" href="<%= cp %>/index.jsp">Retour</a>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const form = document.getElementById("visaForm");
    const typeTitre = document.getElementById("type_titre_id");
    const boxInvestisseur = document.getElementById("box-investisseur");
    const boxTravailleur = document.getElementById("box-travailleur");
    const validateBtn = document.getElementById("validateBtn");
    const saveBtn = document.getElementById("saveBtn");

    const requiredSelectors = [
        "#nom", "#nom_jeune_fille", "#date_naissance", "#situation_famille_id", "#nationalite_id",
        "#adresse_madagascar", "#numero_telephone", "#profession",
        "#numero_passeport", "#date_delivrance", "#date_expiration", "#pays_delivrance",
        "#visa_date_entree", "#visa_lieu_entree", "#visa_date_expiration",
        "#type_demande_id", "#type_titre_id", "#passeport_id"
    ];

    function normalize(str) {
        return (str || "").toLowerCase().trim();
    }

    function toggleSpecificPieces() {
        const selectedText = normalize(typeTitre.options[typeTitre.selectedIndex] ? typeTitre.options[typeTitre.selectedIndex].text : "");
        boxInvestisseur.style.display = selectedText.includes("invest") ? "block" : "none";
        boxTravailleur.style.display = selectedText.includes("travail") ? "block" : "none";
    }

    function hasRequiredFilled() {
        for (const selector of requiredSelectors) {
            const input = form.querySelector(selector);
            if (!input || !String(input.value || "").trim()) {
                return false;
            }
        }
        return true;
    }

    function hasPieceChecked() {
        return form.querySelectorAll("input[name='piece_ids']:checked").length > 0;
    }

    function refreshButtons() {
        const ok = hasRequiredFilled() && hasPieceChecked();
        validateBtn.disabled = !ok;
        saveBtn.disabled = !ok;
    }

    typeTitre.addEventListener("change", function () {
        toggleSpecificPieces();
        refreshButtons();
    });

    form.addEventListener("input", refreshButtons);
    form.addEventListener("change", refreshButtons);

    toggleSpecificPieces();
    refreshButtons();
})();
</script>
</body>
</html>
