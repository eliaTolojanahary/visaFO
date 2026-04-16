<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Nouveau Véhicule</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .form-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #555;
            font-weight: bold;
        }
        input[type="text"],
        input[type="number"],
        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        button {
            width: 100%;
            padding: 12px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
        }
        button:hover {
            background-color: #45a049;
        }
        .back-link {
            display: block;
            text-align: center;
            margin-top: 20px;
            color: #666;
            text-decoration: none;
        }
        .back-link:hover {
            color: #333;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h1>Ajouter un Nouveau Véhicule</h1>
        <form action="save" method="post">
            <div class="form-group">
                <label for="reference">Référence:</label>
                <input type="text" id="reference" name="reference" required placeholder="Ex: VEH-001">
            </div>
            
            <div class="form-group">
                <label for="place">Nombre de Places:</label>
                <input type="number" id="place" name="place" min="1" required placeholder="Ex: 5">
            </div>
            
            <div class="form-group">
                <label for="typeCarburant">Type de Carburant:</label>
                <select id="typeCarburant" name="typeCarburant" required>
                    <option value="">-- Sélectionner --</option>
                    <option value="Essence">Essence</option>
                    <option value="Diesel">Diesel</option>
                    <option value="Electrique">Electrique</option>
                    <option value="Hybride">Hybride</option>
                </select>
            </div>
            
            <button type="submit">Enregistrer</button>
        </form>
    </div>
</body>
</html>
