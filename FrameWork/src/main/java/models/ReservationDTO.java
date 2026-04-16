package models;

import java.time.LocalDateTime;

public class ReservationDTO {
    private int id;
    private String client;
    private String vehicule;
    private String heureDepart;
    private String heureArrivee;
    private String lieuDepart;
    private String lieuArrivee;
    private int nbPassager;
    private String hotel;
    private String dateHeureArrivee;
    private boolean assigned;
    private LocalDateTime heureArriveeParsed; // Pour le tri

    // Constructeur pour réservation non assignée
    public ReservationDTO(Reservation r) {
        this.id = r.getId();
        this.client = r.getClient();
        this.nbPassager = r.getNbPassager();
        this.hotel = r.getHotel();
        this.dateHeureArrivee = r.getDateHeureDepart();
        this.assigned = false;
    }

    // Constructeur pour réservation assignée avec toutes les infos
    public ReservationDTO(Reservation r, Vehicule v, String heureDepart, String heureArrivee, 
                          String lieuDepart, String lieuArrivee, LocalDateTime heureArriveeParsed) {
        this.id = r.getId();
        this.client = r.getClient();
        this.nbPassager = r.getNbPassager();
        this.hotel = r.getHotel();
        this.dateHeureArrivee = r.getDateHeureDepart();
        this.vehicule = v.getReference();
        this.heureDepart = heureDepart;
        this.heureArrivee = heureArrivee;
        this.lieuDepart = lieuDepart;
        this.lieuArrivee = lieuArrivee;
        this.heureArriveeParsed = heureArriveeParsed;
        this.assigned = true;
    }

    // Getters & setters
    public int getId() { return id; }
    public String getClient() { return client; }
    public String getVehicule() { return vehicule; }
    public String getHeureDepart() { return heureDepart; }
    public String getHeureArrivee() { return heureArrivee; }
    public String getLieuDepart() { return lieuDepart; }
    public String getLieuArrivee() { return lieuArrivee; }
    public int getNbPassager() { return nbPassager; }
    public String getHotel() { return hotel; }
    public String getDateHeureArrivee() { return dateHeureArrivee; }
    public boolean isAssigned() { return assigned; }
    public LocalDateTime getHeureArriveeParsed() { return heureArriveeParsed; }

    public void setHeureDepart(String heureDepart) { this.heureDepart = heureDepart; }
    public void setHeureArrivee(String heureArrivee) { this.heureArrivee = heureArrivee; }
    public void setLieuDepart(String lieuDepart) { this.lieuDepart = lieuDepart; }
    public void setLieuArrivee(String lieuArrivee) { this.lieuArrivee = lieuArrivee; }
}
