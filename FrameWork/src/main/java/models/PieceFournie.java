package models;

import java.sql.Timestamp;

public class PieceFournie {
    private long id;
    private long demande_id;
    private PieceJustificative piece_ref;
    private String chemin_fichier;
    private String nom_fichier;
    private long taille_bytes;
    private String mime_type;
    private Timestamp uploaded_at;
    private boolean cochee;
    private long piece_ref_id;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public long getDemande_id() { return demande_id; }
    public void setDemande_id(long demande_id) { this.demande_id = demande_id; }

    public PieceJustificative getPiece_ref() { return piece_ref; }
    public void setPiece_ref(PieceJustificative piece_ref) { this.piece_ref = piece_ref; }

    public String getChemin_fichier() { return chemin_fichier; }
    public void setChemin_fichier(String chemin_fichier) { this.chemin_fichier = chemin_fichier; }

    public String getNom_fichier() { return nom_fichier; }
    public void setNom_fichier(String nom_fichier) { this.nom_fichier = nom_fichier; }

    public long getTaille_bytes() { return taille_bytes; }
    public void setTaille_bytes(long taille_bytes) { this.taille_bytes = taille_bytes; }

    public String getMime_type() { return mime_type; }
    public void setMime_type(String mime_type) { this.mime_type = mime_type; }

    public Timestamp getUploaded_at() { return uploaded_at; }
    public void setUploaded_at(Timestamp uploaded_at) { this.uploaded_at = uploaded_at; }

    public boolean isCochee() { return cochee; }
    public void setCochee(boolean cochee) { this.cochee = cochee; }

    public long getPiece_ref_id() { return piece_ref_id; }
    public void setPiece_ref_id(long piece_ref_id) { this.piece_ref_id = piece_ref_id; }
}
