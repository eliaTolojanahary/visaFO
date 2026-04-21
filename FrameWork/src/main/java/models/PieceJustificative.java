package models;

public class PieceJustificative {
    private long id;
    private String libelle;
    private TypeTitre type_titre;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }

    public TypeTitre getType_titre() { return type_titre; }
    public void setType_titre(TypeTitre type_titre) { this.type_titre = type_titre; }
}