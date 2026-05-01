package services;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class QrCodeService {

    private static final int QR_WIDTH = 300;
    private static final int QR_HEIGHT = 300;
    private static final String DEFAULT_FRONTEND_BASE_URL = "http://localhost:5173";

    public String genererQrCode(String numDemande) throws Exception {
        if (numDemande == null || numDemande.trim().isEmpty()) {
            throw new IllegalArgumentException("numDemande est obligatoire.");
        }

        String url = buildFrontendUrl(numDemande.trim());
        BitMatrix matrix = new MultiFormatWriter().encode(
            url, BarcodeFormat.QR_CODE, QR_WIDTH, QR_HEIGHT
        );

        Path outputDir = resolveOutputDirectory();
        Files.createDirectories(outputDir);

        Path outputPath = outputDir.resolve(numDemande.trim() + ".png");
        MatrixToImageWriter.writeToPath(matrix, "PNG", outputPath);

        return outputPath.toString();
    }

    public String getQrCodeWebUrl(String numDemande) {
        return "/qrcodes/" + numDemande.trim() + ".png";
    }

    private String buildFrontendUrl(String numDemande) {
        String baseUrl = readConfig("VUE_APP_URL", DEFAULT_FRONTEND_BASE_URL);
        if (baseUrl.endsWith("/")) baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        return baseUrl + "/suivi?numDemande=" + URLEncoder.encode(numDemande, StandardCharsets.UTF_8);
    }

    private Path resolveOutputDirectory() {
        String outputDir = readConfig("QR_OUTPUT_DIR", null);
        if (outputDir != null) return Paths.get(outputDir);

        String catalinaBase = System.getProperty("catalina.base");
        if (catalinaBase != null) {
            return Paths.get(catalinaBase, "webapps", "ROOT", "qrcodes");
        }
        return Paths.get("C:/xampp/tomcat/webapps/ROOT/qrcodes");
    }

    private String readConfig(String key, String defaultValue) {
        String env = System.getenv(key);
        if (env != null && !env.trim().isEmpty()) return env.trim();
        String prop = System.getProperty(key);
        if (prop != null && !prop.trim().isEmpty()) return prop.trim();
        return defaultValue;
    }
}