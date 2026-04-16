package models;

public class Lieu {
    private int id;
    private String code;
    private String libelle;
    
    public Lieu() {
    }
    
    public Lieu(int id, String code, String libelle) {
        this.id = id;
        this.code = code;
        this.libelle = libelle;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public String getCode() {
        return code;
    }
    
    public String getLibelle() {
        return libelle;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setCode(String code) {
        this.code = code;
    }
    
    public void setLibelle(String libelle) {
        this.libelle = libelle;
    }
    
    @Override
    public String toString() {
        return "Lieu{" +
                "id=" + id +
                ", code='" + code + '\'' +
                ", libelle='" + libelle + '\'' +
                '}';
    }
}
