package models;

import java.time.LocalTime;
import annotation.RequestParam;

public class Vehicule {
    private int id;
    private String reference;
    private int place;
    private String typeCarburant;
    private LocalTime heureDisponibilite; // The earliest time the vehicle is available for the day
    
    public Vehicule() {
    }

    public Vehicule(
            @RequestParam("reference") String reference,
            @RequestParam("place") int place,
            @RequestParam("typeCarburant") String typeCarburant,
            @RequestParam("heureDisponibilite") String heureDisponibiliteStr) {
        this.reference = reference;
        this.place = place;
        this.typeCarburant = typeCarburant;
        if (heureDisponibiliteStr != null && !heureDisponibiliteStr.isEmpty()) {
            this.heureDisponibilite = LocalTime.parse(heureDisponibiliteStr);
        }
    }

    public Vehicule(int id, String reference, int place, String typeCarburant, LocalTime heureDisponibilite) {
        this.id = id;
        this.reference = reference;
        this.place = place;
        this.typeCarburant = typeCarburant;
        this.heureDisponibilite = heureDisponibilite;
    }
    
    // Legacy constructor for backward compatibility
    Vehicule(int id, String reference, int place, String typeCarburant) {
        this.id = id;
        this.reference = reference;
        this.place = place;
        this.typeCarburant = typeCarburant;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public String getReference() {
        return reference;
    }
    
    public int getPlace() {
        return place;
    }
    
    public String getTypeCarburant() {
        return typeCarburant;
    }
    
    public LocalTime getHeureDisponibilite() {
        return heureDisponibilite;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setReference(String reference) {
        this.reference = reference;
    }
    
    public void setPlace(int place) {
        this.place = place;
    }
    
    public void setTypeCarburant(String typeCarburant) {
        this.typeCarburant = typeCarburant;
    }
    
    public void setHeureDisponibilite(LocalTime heureDisponibilite) {
        this.heureDisponibilite = heureDisponibilite;
    }
    
    @Override
    public String toString() {
        return "Vehicule{" +
                "id=" + id +
                ", reference='" + reference + '\'' +
                ", place=" + place +
                ", typeCarburant='" + typeCarburant + '\'' +
                ", heureDisponibilite=" + heureDisponibilite +
                '}';
    }
}
