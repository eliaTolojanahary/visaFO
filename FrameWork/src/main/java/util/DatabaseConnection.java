package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseConnection {

    private static final String URL;
    private static final String USER;
    private static final String PASSWORD;

    static {
        loadEnvFile();
        URL      = getEnvOrDefault("DB_URL",      "jdbc:postgresql://localhost:5432/visa");
        USER     = getEnvOrDefault("DB_USER",     "postgres");
        PASSWORD = getEnvOrDefault("DB_PASSWORD", "NouveauMotDePasse");

        try {
            Class.forName("org.postgresql.Driver");
            // System.out.println("✓ Driver PostgreSQL chargé avec succès");
        } catch (ClassNotFoundException e) {
            System.err.println("✗ ERREUR: Driver PostgreSQL non trouvé!");
            System.err.println("  Assurez-vous que postgresql-XX.jar est dans WEB-INF/lib/");
            e.printStackTrace();
            throw new RuntimeException("PostgreSQL Driver not found. Add postgresql-XX.jar to WEB-INF/lib/", e);
        }
    }

    /**
     * Cherche .env dans l'ordre :
     *   1. APP_HOME  — injecté par Tomcat via CATALINA_OPTS=-DAPP_HOME=...
     *   2. user.dir  — fonctionne pour les tests en ligne de commande
     *
     * Le .env ne doit jamais être commité sur Git.
     * Utiliser .env.example comme template pour l'équipe.
     */
    private static void loadEnvFile() {
        String appHome = System.getProperty("APP_HOME");
        String userDir = System.getProperty("user.dir");

        String[] candidates = {
            appHome != null ? appHome + "/.env"   : null,
            appHome != null ? appHome + "\\.env"  : null,
            userDir != null ? userDir + "/.env"   : null,
            userDir != null ? userDir + "\\.env"  : null,
            // Fallback explicite pour XAMPP — user.dir pointe vers CATALINA_HOME\bin
            "C:\\xampp\\tomcat\\bin\\.env"
        };

        java.io.File envFile = null;
        for (String path : candidates) {
            if (path == null) continue;
            java.io.File f = new java.io.File(path);
            if (f.exists()) {
                envFile = f;
                break;
            }
        }

        if (envFile == null) {
            System.err.println("⚠ Avertissement: fichier .env introuvable");
            System.err.println("  APP_HOME = " + appHome);
            System.err.println("  user.dir = " + userDir);
            System.err.println("  → Utilisation des valeurs par défaut");
            return;
        }

        // System.out.println("✓ Chargement .env depuis: " + envFile.getAbsolutePath());
        try (java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.FileReader(envFile))) {
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("#")) continue;
                int idx = line.indexOf('=');
                if (idx < 0) continue;
                String key   = line.substring(0, idx).trim();
                String value = line.substring(idx + 1).trim();
                System.setProperty(key, value);
                // System.out.println("  - " + key + " chargé");
            }
        } catch (java.io.IOException e) {
            System.err.println("✗ Erreur lecture .env: " + e.getMessage());
        }
    }

    /**
     * Priorité :
     *   1. Variable d'environnement système Windows
     *   2. Property chargée depuis .env
     *   3. Valeur par défaut
     */
    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        if (value != null) return value;
        value = System.getProperty(key);
        return value != null ? value : defaultValue;
    }

    public static Connection getConnection() throws SQLException {
        try {
            Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
            try (Statement stmt = conn.createStatement()) {
                stmt.execute("SET search_path TO public");
            }
            // System.out.println("✓ Connexion à la base de données réussie");
            return conn;
        } catch (SQLException e) {
            System.err.println("✗ ERREUR de connexion à la base de données:");
            System.err.println("  URL:     " + URL);
            System.err.println("  User:    " + USER);
            System.err.println("  Message: " + e.getMessage());
            throw e;
        }
    }
}