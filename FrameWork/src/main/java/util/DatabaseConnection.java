package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static final String URL = "jdbc:postgresql://localhost:5432/reservation";
    private static final String USER = "postgres";
    private static final String PASSWORD = "NouveauMotDePasse";
    
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
