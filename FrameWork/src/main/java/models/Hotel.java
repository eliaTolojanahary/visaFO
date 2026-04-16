package models;

public class Hotel {
    private int id;
    private String nom;
    private String adresse;
    
    public Hotel() {
    }
    
    public Hotel(int id, String nom, String adresse) {
        this.id = id;
        this.nom = nom;
        this.adresse = adresse;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public String getNom() {
        return nom;
    }
    
    public String getAdresse() {
        return adresse;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setNom(String nom) {
        this.nom = nom;
    }
    
    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }
    
    @Override
    public String toString() {
        return "Hotel{" +
                "id=" + id +
                ", nom='" + nom + '\'' +
                ", adresse='" + adresse + '\'' +
                '}';
    }
}
