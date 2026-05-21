package util;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

/**
 * Charge le fichier .env une seule fois au démarrage.
 * Priorité : System.getenv() > System.getProperty() > .env > valeur par défaut
 */
public class AppConfig {

    private static final AppConfig INSTANCE = new AppConfig();
    private final Map<String, String> envVars = new HashMap<>();

    private AppConfig() {
        loadDotEnv();
    }

    public static AppConfig getInstance() {
        return INSTANCE;
    }

    public String get(String key, String defaultValue) {
        // 1. Variable d'environnement OS (priorité maximale)
        String val = System.getenv(key);
        if (val != null && !val.isBlank()) return val.trim();

        // 2. Propriété JVM (-DKEY=value)
        val = System.getProperty(key);
        if (val != null && !val.isBlank()) return val.trim();

        // 3. .env chargé en mémoire
        val = envVars.get(key);
        if (val != null && !val.isBlank()) return val.trim();

        return defaultValue;
    }

    private void loadDotEnv() {
        Path envFile = resolveEnvFile();
        if (envFile == null || !Files.exists(envFile)) {
            System.out.println("[AppConfig] Aucun fichier .env trouvé, on continue avec les variables système.");
            return;
        }

        Properties props = new Properties();
        try (InputStream is = Files.newInputStream(envFile)) {
            props.load(is);
            for (String key : props.stringPropertyNames()) {
                envVars.put(key.trim(), props.getProperty(key).trim());
            }
            System.out.println("[AppConfig] .env chargé depuis : " + envFile);
        } catch (IOException e) {
            System.err.println("[AppConfig] Erreur lecture .env : " + e.getMessage());
        }
    }

    /**
     * Cherche le .env dans cet ordre :
     * 1. APP_ENV_PATH (variable d'env ou propriété JVM explicite)
     * 2. Répertoire de travail courant
     * 3. Racine du projet via catalina.base/../
     */
    private Path resolveEnvFile() {
        // Chemin explicite configuré
        String explicit = System.getenv("APP_ENV_PATH");
        if (explicit == null) explicit = System.getProperty("APP_ENV_PATH");
        if (explicit != null) return Paths.get(explicit);

        // Répertoire courant (fonctionne en dev local)
        Path cwd = Paths.get(System.getProperty("user.dir"), ".env");
        if (Files.exists(cwd)) return cwd;

        // Déployé sous Tomcat : remonter d'un niveau depuis catalina.base
        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null) {
            Path catalinaEnv = Paths.get(catalinaBase).getParent().resolve(".env");
            if (Files.exists(catalinaEnv)) return catalinaEnv;
        }

        return null;
    }
}