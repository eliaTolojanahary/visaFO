package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseConnection {
    private static final String URL = getEnvOrDefault("DB_URL", "jdbc:postgresql://localhost:5432/visa");
    private static final String USER = getEnvOrDefault("DB_USER", "postgres");
    private static final String PASSWORD = getEnvOrDefault("DB_PASSWORD", "1234");
    
    /**
     * Récupère une variable d'environnement ou retourne une valeur par défaut
     */
    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return value != null ? value : defaultValue;
    }
    
    static {
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("✓ Driver PostgreSQL chargé avec succès");
        } catch (ClassNotFoundException e) {
            System.err.println("✗ ERREUR: Driver PostgreSQL non trouvé!");
            System.err.println("  Assurez-vous que postgresql-XX.jar est dans WEB-INF/lib/");
            e.printStackTrace();
            throw new RuntimeException("PostgreSQL Driver not found. Add postgresql-XX.jar to WEB-INF/lib/", e);
        }
    }
    
    public static Connection getConnection() throws SQLException {
        try {
            Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
            try (Statement stmt = conn.createStatement()) {
                // Force le schéma attendu pour éviter toute résolution implicite vers un schéma inexistant.
                stmt.execute("SET search_path TO public");
            }
            System.out.println("✓ Connexion à la base de données réussie");
            return conn;
        } catch (SQLException e) {
            System.err.println("✗ ERREUR de connexion à la base de données:");
            System.err.println("  URL: " + URL);
            System.err.println("  User: " + USER);
            System.err.println("  Message: " + e.getMessage());
            throw e;
        }
    }
}
