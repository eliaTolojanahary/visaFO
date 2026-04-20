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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulaire de Demande Visa</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }
        .section h2 {
            color: #333;
            margin-bottom: 12px;
            font-size: 20px;
        }
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 15px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input[type="text"],
        input[type="email"],
        input[type="number"],
        input[type="date"],
        select,
        textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        textarea {
            min-height: 80px;
            resize: vertical;
        }
        .pieces-wrap {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 15px;
        }
        .piece-box {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 10px;
            background-color: #fafafa;
        }
        .piece-box h3 {
            margin: 0 0 8px;
            color: #333;
            font-size: 16px;
        }
        .piece-list {
            display: grid;
            gap: 8px;
            max-height: 220px;
            overflow: auto;
        }
        .piece-item {
            display: flex;
            align-items: center;
            gap: 8px;
            color: #333;
        }
        .piece-specific {
            display: none;
        }
        .actions {
            display: flex;
            justify-content: center;
            gap: 10px;
            flex-wrap: wrap;
            margin-top: 15px;
        }
        .btn {
            border: none;
            border-radius: 4px;
            padding: 12px 20px;
            font-size: 15px;
            font-weight: bold;
            cursor: pointer;
            color: white;
            text-decoration: none;
            display: inline-block;
        }
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        .btn-validate {
            background-color: #4CAF50;
        }
        .btn-validate:hover {
            background-color: #45a049;
        }
        .btn-save {
            background-color: #2196F3;
        }
        .btn-save:hover {
            background-color: #0b7dda;
        }
        .btn-update {
            background-color: #ff9800;
        }
        .btn-update:hover {
            background-color: #e68900;
        }
        .btn-back {
            background-color: #666;
        }
        .btn-back:hover {
            background-color: #555;
        }
        .required::after {
            content: " *";
            color: red;
        }
        .notice {
            color: green;
            margin-bottom: 15px;
            padding: 10px;
            background-color: #dfd;
            border-radius: 4px;
        }
        @media (max-width: 640px) {
            body {
                margin: 20px;
            }
            .btn {
                width: 100%;
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Formulaire de Demande Visa</h1>

        <% if (message != null && !message.isEmpty()) { %>
            <div class="notice"><%= message %></div>
        <% } %>

        <form id="visaForm" action="<%= cp %>/visa/form" method="post">
            <div class="section">
                <h2>Type de demande</h2>
                <div class="form-grid">
                    <div class="form-group">
                        <label class="required" for="type_demande_id">Categorie de demande</label>
                        <select id="type_demande_id" name="type_demande_id" required>
                            <option value="">-- Choisir --</option>
                            <option value="1" <%= "1".equals(value(formData, "type_demande_id")) ? "selected" : "" %>>Nouveau titre</option>
                            <option value="2" disabled>Duplicata (Sprint futur)</option>
                            <option value="3" disabled>Transfert de visa (Sprint futur)</option>
                        </select>
                    </div>
                    <div class="form-group">
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
                    <div class="form-group">
                        <label class="required" for="passeport_id">Passeport ID (test local)</label>
                        <input id="passeport_id" name="passeport_id" type="number" min="1" value="<%= value(formData, "passeport_id") %>" required>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Etat civil</h2>
                <div class="form-grid">
                    <div class="form-group">
                        <label class="required" for="nom">Nom</label>
                        <input id="nom" name="nom" value="<%= value(formData, "nom") %>" required>
                    </div>
                    <div class="form-group">
                        <label for="prenom">Prenom</label>
                        <input id="prenom" name="prenom" value="<%= value(formData, "prenom") %>">
                    </div>
                    <div class="form-group">
                        <label class="required" for="nom_jeune_fille">Nom de jeune fille</label>
                        <input id="nom_jeune_fille" name="nom_jeune_fille" value="<%= value(formData, "nom_jeune_fille") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="date_naissance">Date de naissance</label>
                        <input id="date_naissance" name="date_naissance" type="date" value="<%= value(formData, "date_naissance") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="situation_famille_id">Situation de famille (id)</label>
                        <input id="situation_famille_id" name="situation_famille_id" type="number" min="1" value="<%= value(formData, "situation_famille_id") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="nationalite_id">Nationalite (id)</label>
                        <input id="nationalite_id" name="nationalite_id" type="number" min="1" value="<%= value(formData, "nationalite_id") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="adresse_madagascar">Adresse Madagascar</label>
                        <textarea id="adresse_madagascar" name="adresse_madagascar" required><%= value(formData, "adresse_madagascar") %></textarea>
                    </div>
                    <div class="form-group">
                        <label class="required" for="numero_telephone">Numero telephone</label>
                        <input id="numero_telephone" name="numero_telephone" value="<%= value(formData, "numero_telephone") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="profession">Profession</label>
                        <input id="profession" name="profession" value="<%= value(formData, "profession") %>" required>
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input id="email" name="email" type="email" value="<%= value(formData, "email") %>">
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Passeport</h2>
                <div class="form-grid">
                    <div class="form-group">
                        <label class="required" for="numero_passeport">Numero passeport</label>
                        <input id="numero_passeport" name="numero_passeport" value="<%= value(formData, "numero_passeport") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="date_delivrance">Date de delivrance</label>
                        <input id="date_delivrance" name="date_delivrance" type="date" value="<%= value(formData, "date_delivrance") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="date_expiration">Date d'expiration</label>
                        <input id="date_expiration" name="date_expiration" type="date" value="<%= value(formData, "date_expiration") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="pays_delivrance">Pays de delivrance</label>
                        <input id="pays_delivrance" name="pays_delivrance" value="<%= value(formData, "pays_delivrance") %>" required>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>Visa</h2>
                <div class="form-grid">
                    <div class="form-group">
                        <label class="required" for="visa_date_entree">Date d'entree</label>
                        <input id="visa_date_entree" name="visa_date_entree" type="date" value="<%= value(formData, "visa_date_entree") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="visa_lieu_entree">Lieu d'entree</label>
                        <input id="visa_lieu_entree" name="visa_lieu_entree" value="<%= value(formData, "visa_lieu_entree") %>" required>
                    </div>
                    <div class="form-group">
                        <label class="required" for="visa_date_expiration">Date d'expiration</label>
                        <input id="visa_date_expiration" name="visa_date_expiration" type="date" value="<%= value(formData, "visa_date_expiration") %>" required>
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
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %>>
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
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %>>
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
                                        <input type="checkbox" name="piece_ids" value="<%= p.getId() %>" <%= isChecked(formData, p.getId()) ? "checked" : "" %>>
                                        <span><%= p.getLibelle() %></span>
                                    </label>
                            <%  }
                            } %>
                        </div>
                    </div>
                </div>

                <div class="actions">
                    <button id="validateBtn" class="btn btn-validate" type="submit" formaction="<%= cp %>/visa/form">Soumettre</button>
                    <button id="saveBtn" class="btn btn-save" type="submit" formaction="<%= cp %>/visa/form/save" disabled>Enregistrer</button>
                    <button class="btn btn-update" type="submit" formaction="<%= cp %>/visa/form/update">Mettre a jour</button>
                    <a class="btn btn-back" href="<%= cp %>/index.jsp">Retour</a>
                </div>
            </div>
        </form>
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
