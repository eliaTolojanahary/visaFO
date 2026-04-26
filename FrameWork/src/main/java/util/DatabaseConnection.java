package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Gestion de la connexion à la base de données PostgreSQL.
 *
 * SÉCURITÉ : les credentials ne sont PLUS en dur dans le code.
 * Ils sont lus depuis les variables d'environnement suivantes :
 *   DB_URL      → URL JDBC  (ex: jdbc:postgresql://localhost:5432/visa)
 *   DB_USER     → utilisateur PostgreSQL (ex: postgres)
 *   DB_PASSWORD → mot de passe PostgreSQL
 *
 * Copier .env.example → .env à la racine du projet et remplir les vraies valeurs.
 * Ne jamais committer .env (il est dans .gitignore).
 */
public class DatabaseConnection {

    // -------------------------------------------------------------------------
    // Lecture des variables d'environnement avec valeurs de fallback explicites
    // pour faciliter le diagnostic en cas de variable manquante.
    // -------------------------------------------------------------------------
    private static final String URL      = getEnvOrFail("DB_URL");
    private static final String USER     = getEnvOrFail("DB_USER");
    private static final String PASSWORD = getEnvOrFail("DB_PASSWORD");

    /**
     * Lit une variable d'environnement obligatoire.
     * Lance une exception explicite si elle est absente ou vide,
     * plutôt qu'un NullPointerException silencieux plus tard.
     */
    private static String getEnvOrFail(String key) {
        String value = System.getenv(key);
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalStateException(
                "Variable d'environnement manquante : " + key +
                ". Vérifiez votre fichier .env ou les variables système."
            );
        }
        return value;
    }

    // Chargement du driver PostgreSQL au démarrage de la classe
    static {
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("✔ Driver PostgreSQL chargé avec succès");
        } catch (ClassNotFoundException e) {
            System.err.println("✘ ERREUR: Driver PostgreSQL non trouvé !");
            System.err.println("  Assurez-vous que postgresql-XX.jar est dans WEB-INF/lib/");
            e.printStackTrace();
            throw new RuntimeException(
                "PostgreSQL Driver not found. Add postgresql-XX.jar to WEB-INF/lib/", e
            );
        }
    }

    /**
     * Ouvre et retourne une connexion à la base de données.
     * Force le search_path vers 'public' pour éviter toute résolution
     * implicite vers un schéma inexistant.
     *
     * @return connexion JDBC active
     * @throws SQLException si la connexion échoue
     */
    public static Connection getConnection() throws SQLException {
        try {
            Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
            try (Statement stmt = conn.createStatement()) {
                // Force le schéma attendu pour éviter tout problème de résolution implicite
                stmt.execute("SET search_path TO public");
            }
            System.out.println("✔ Connexion à la base de données réussie");
            return conn;
        } catch (SQLException e) {
            System.err.println("✘ ERREUR de connexion à la base de données:");
            // On log l'URL et l'utilisateur pour le diagnostic,
            // mais JAMAIS le mot de passe dans les logs.
            System.err.println("  URL:     " + URL);
            System.err.println("  User:    " + USER);
            System.err.println("  Message: " + e.getMessage());
            throw e;
        }
    }
}