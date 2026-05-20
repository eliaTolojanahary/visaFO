package services;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.zip.DeflaterOutputStream;
import javax.imageio.ImageIO;
import models.PieceFournie;
import util.DownloadFileResponse;

public class AttestationPdfService {

    private static final Charset PDF_TEXT_CHARSET = Charset.forName("windows-1252");
    private static final String PHOTO_LIBELLE = "Photo d'identité (webcam)";
    private static final String STATUT_SCAN_TERMINE = "SCAN TERMINE";

    private final ScanService scanService = new ScanService();
    private final QrCodeService qrCodeService = new QrCodeService();

    public DownloadFileResponse genererAttestation(long demandeId) throws SQLException {
        Map<String, Object> fiche = scanService.getFicheDemandeData(demandeId);
        if (fiche == null) {
            throw new IllegalArgumentException("Demande introuvable: " + demandeId);
        }

        String statut = firstNonBlank(
            fiche.get("statut"),
            fiche.get("statutLibelle"),
            fiche.get("statut_libelle")
        );
        if (!isScanTermine(statut)) {
            throw new IllegalStateException("L'attestation PDF est accessible uniquement lorsque le dossier est SCAN TERMINE.");
        }

        String reference = firstNonBlank(fiche.get("ref_demande"), fiche.get("reference"));
        String nom = firstNonBlank(fiche.get("nom"));
        String prenom = firstNonBlank(fiche.get("prenom"));
        String nomComplet = (nom + " " + prenom).trim();
        String createdAt = firstNonBlank(fiche.get("createdAt"), fiche.get("created_at"));
        String numeroPasseport = firstNonBlank(fiche.get("numeroPasseport"), fiche.get("numero_passeport"));
        String typeDemande = firstNonBlank(fiche.get("typeDemandeLibelle"), fiche.get("type_demande_libelle"));
        String typeTitre = firstNonBlank(fiche.get("typeTitreLibelle"), fiche.get("type_titre_libelle"));

        PdfImage photoImage = loadPhotoImage(fiche);
        PdfImage qrImage = loadQrImage(reference);

        byte[] pdf = buildPdf(
            reference,
            nomComplet,
            createdAt,
            numeroPasseport,
            typeDemande,
            typeTitre,
            statut,
            photoImage,
            qrImage
        );

        String filename = buildFilename(reference);
        return new DownloadFileResponse(pdf, filename, "application/pdf");
    }

    private boolean isScanTermine(String statut) {
        if (statut == null) {
            return false;
        }
        String normalized = statut.trim().toUpperCase(Locale.ROOT);
        return STATUT_SCAN_TERMINE.equals(normalized) || "SCAN TERMINÉ".equals(normalized);
    }

    private PdfImage loadPhotoImage(Map<String, Object> fiche) {
        try {
            long demandeId = longValue(fiche.get("demandeId"), longValue(fiche.get("demande_id"), -1L));
            if (demandeId < 0) {
                return placeholderImage("Photo indisponible", 180, 220);
            }

            long pieceRefId = scanService.getPieceRefIdByLibelle(PHOTO_LIBELLE);
            if (pieceRefId < 0) {
                return placeholderImage("Photo indisponible", 180, 220);
            }

            PieceFournie piece = scanService.getPieceFournie(demandeId, pieceRefId);
            if (piece == null || piece.getChemin_fichier() == null) {
                return placeholderImage("Photo indisponible", 180, 220);
            }

            Path path = Paths.get(piece.getChemin_fichier());
            if (!Files.exists(path)) {
                return placeholderImage("Photo indisponible", 180, 220);
            }

            BufferedImage image = ImageIO.read(path.toFile());
            if (image == null) {
                return placeholderImage("Photo indisponible", 180, 220);
            }
            return toPdfImage(image);
        } catch (IOException | SQLException | RuntimeException ignored) {
            return placeholderImage("Photo indisponible", 180, 220);
        }
    }

    private PdfImage loadQrImage(String reference) {
        try {
            if (reference == null || reference.trim().isEmpty()) {
                return placeholderImage("QR indisponible", 200, 200);
            }

            String pathString = qrCodeService.genererQrCode(reference.trim());
            if (pathString == null || pathString.trim().isEmpty()) {
                return placeholderImage("QR indisponible", 200, 200);
            }

            Path path = Paths.get(pathString);
            if (!Files.exists(path)) {
                return placeholderImage("QR indisponible", 200, 200);
            }

            BufferedImage image = ImageIO.read(path.toFile());
            if (image == null) {
                return placeholderImage("QR indisponible", 200, 200);
            }
            return toPdfImage(image);
        } catch (IOException | RuntimeException ignored) {
            return placeholderImage("QR indisponible", 200, 200);
        }
    }

    private byte[] buildPdf(String reference, String nomComplet, String createdAt, String numeroPasseport,
            String typeDemande, String typeTitre, String statut, PdfImage photoImage, PdfImage qrImage) throws SQLException {
        StringBuilder content = new StringBuilder();
        content.append(textLine(40, 800, "Attestation de reception du dossier", 18));
        content.append(textLine(40, 770, "Reference dossier: " + safe(reference), 11));
        content.append(textLine(40, 750, "Statut: " + safe(statut), 11));
        content.append(textLine(40, 730, "Date creation / obtention: " + safe(createdAt), 11));
        content.append(textLine(40, 710, "Demandeur: " + safe(nomComplet), 11));
        content.append(textLine(40, 690, "Numero passeport: " + safe(numeroPasseport), 11));
        content.append(textLine(40, 670, "Type demande: " + safe(typeDemande), 11));
        content.append(textLine(40, 650, "Type document: " + safe(typeTitre), 11));
        content.append(textLine(40, 620, "Lecture seule depuis l'application.", 11));
        content.append(textLine(40, 590, "Le dossier est consultable uniquement apres SCAN TERMINE.", 11));

        if (photoImage != null) {
            content.append("q 180 0 0 220 355 560 cm /Im1 Do Q\n");
        }
        if (qrImage != null) {
            content.append("q 150 0 0 150 390 360 cm /Im2 Do Q\n");
        }

        return buildSinglePagePdf(content.toString(), photoImage, qrImage);
    }

    private byte[] buildSinglePagePdf(String content, PdfImage photoImage, PdfImage qrImage) throws SQLException {
        try {
            List<byte[]> objects = new ArrayList<>();
            objects.add(asciiObject("<< /Type /Catalog /Pages 2 0 R >>"));
            objects.add(asciiObject("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"));

            StringBuilder resources = new StringBuilder();
            resources.append("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >>");
            if (photoImage != null || qrImage != null) {
                resources.append(" /XObject <<");
                if (photoImage != null) {
                    resources.append(" /Im1 6 0 R");
                }
                if (qrImage != null) {
                    resources.append(photoImage != null ? " /Im2 7 0 R" : " /Im2 6 0 R");
                }
                resources.append(" >>");
            }
            resources.append(" >> /Contents 5 0 R >>");
            objects.add(asciiObject(resources.toString()));
            objects.add(asciiObject("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"));
            objects.add(streamObject(content.getBytes(PDF_TEXT_CHARSET), null));

            if (photoImage != null) {
                objects.add(streamObject(photoImage.data, imageDictionary(photoImage.width, photoImage.height)));
            }
            if (qrImage != null) {
                objects.add(streamObject(qrImage.data, imageDictionary(qrImage.width, qrImage.height)));
            }

            return writePdf(objects);
        } catch (IOException e) {
            throw new SQLException("Impossible de generer le PDF d'attestation.", e);
        }
    }

    private Map<String, String> imageDictionary(int width, int height) {
        Map<String, String> dict = new java.util.LinkedHashMap<>();
        dict.put("/Type", "/XObject");
        dict.put("/Subtype", "/Image");
        dict.put("/Width", String.valueOf(width));
        dict.put("/Height", String.valueOf(height));
        dict.put("/ColorSpace", "/DeviceRGB");
        dict.put("/BitsPerComponent", "8");
        dict.put("/Filter", "/FlateDecode");
        return dict;
    }

    private PdfImage toPdfImage(BufferedImage source) throws IOException {
        BufferedImage rgb = new BufferedImage(source.getWidth(), source.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = rgb.createGraphics();
        graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, rgb.getWidth(), rgb.getHeight());
        graphics.drawImage(source, 0, 0, null);
        graphics.dispose();

        ByteArrayOutputStream raw = new ByteArrayOutputStream();
        for (int y = 0; y < rgb.getHeight(); y++) {
            for (int x = 0; x < rgb.getWidth(); x++) {
                int pixel = rgb.getRGB(x, y);
                raw.write((pixel >> 16) & 0xff);
                raw.write((pixel >> 8) & 0xff);
                raw.write(pixel & 0xff);
            }
        }

        ByteArrayOutputStream compressed = new ByteArrayOutputStream();
        try (DeflaterOutputStream deflater = new DeflaterOutputStream(compressed)) {
            deflater.write(raw.toByteArray());
        }

        return new PdfImage(rgb.getWidth(), rgb.getHeight(), compressed.toByteArray());
    }

    private PdfImage placeholderImage(String label, int width, int height) {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, width, height);
        graphics.setColor(new Color(215, 215, 215));
        graphics.drawRect(0, 0, width - 1, height - 1);
        graphics.setColor(Color.DARK_GRAY);
        graphics.setFont(new Font("SansSerif", Font.PLAIN, 14));
        graphics.drawString(label, 12, Math.max(20, height / 2));
        graphics.dispose();

        try {
            return toPdfImage(image);
        } catch (IOException e) {
            return null;
        }
    }

    private byte[] writePdf(List<byte[]> objects) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write("%PDF-1.4\n".getBytes(StandardCharsets.US_ASCII));

        List<Integer> offsets = new ArrayList<>();
        offsets.add(0);
        for (int i = 0; i < objects.size(); i++) {
            offsets.add(out.size());
            out.write((i + 1 + " 0 obj\n").getBytes(StandardCharsets.US_ASCII));
            out.write(objects.get(i));
            out.write("\nendobj\n".getBytes(StandardCharsets.US_ASCII));
        }

        int xrefOffset = out.size();
        out.write(("xref\n0 " + (objects.size() + 1) + "\n").getBytes(StandardCharsets.US_ASCII));
        out.write("0000000000 65535 f \n".getBytes(StandardCharsets.US_ASCII));
        for (int offset : offsets.subList(1, offsets.size())) {
            out.write(String.format("%010d 00000 n \n", offset).getBytes(StandardCharsets.US_ASCII));
        }
        out.write(("trailer\n<< /Size " + (objects.size() + 1) + " /Root 1 0 R >>\n").getBytes(StandardCharsets.US_ASCII));
        out.write(("startxref\n" + xrefOffset + "\n%%EOF").getBytes(StandardCharsets.US_ASCII));
        return out.toByteArray();
    }

    private byte[] asciiObject(String value) {
        return value.getBytes(StandardCharsets.US_ASCII);
    }

    private byte[] streamObject(byte[] stream, Map<String, String> dictionary) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        StringBuilder header = new StringBuilder();
        header.append("<< /Length ").append(stream.length);
        if (dictionary != null) {
            for (Map.Entry<String, String> entry : dictionary.entrySet()) {
                header.append(' ').append(entry.getKey()).append(' ').append(entry.getValue());
            }
        }
        header.append(" >>\nstream\n");
        out.write(header.toString().getBytes(StandardCharsets.US_ASCII));
        out.write(stream);
        out.write("\nendstream".getBytes(StandardCharsets.US_ASCII));
        return out.toByteArray();
    }

    private String textLine(int x, int y, String text, int size) {
        return "BT /F1 " + size + " Tf " + x + " " + y + " Td (" + escape(text) + ") Tj ET\n";
    }

    private String escape(String text) {
        String value = safe(text);
        return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private String firstNonBlank(Object... values) {
        if (values == null) {
            return "";
        }
        for (Object value : values) {
            if (value == null) {
                continue;
            }
            String text = String.valueOf(value).trim();
            if (!text.isEmpty() && !"null".equalsIgnoreCase(text)) {
                return text;
            }
        }
        return "";
    }

    private long longValue(Object value, long fallback) {
        if (value == null) {
            return fallback;
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private String buildFilename(String reference) {
        String safeReference = reference == null || reference.trim().isEmpty() ? "attestation" : reference.trim();
        return safeReference.replaceAll("[^a-zA-Z0-9._-]", "_") + "-attestation.pdf";
    }

    private static final class PdfImage {
        private final int width;
        private final int height;
        private final byte[] data;

        private PdfImage(int width, int height, byte[] data) {
            this.width = width;
            this.height = height;
            this.data = data;
        }
    }
}
