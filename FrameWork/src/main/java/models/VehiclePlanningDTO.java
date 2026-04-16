package models;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class VehiclePlanningDTO {
    private int idVehicule;
    private String referenceVehicule;
    private String dateHeureDepart;  
    private String dateHeureRetour;   
    private List<ClientInfo> clients; 
    private LocalDateTime heureRetourParsed; 
    private int placesOccupees;
    private int placesTotales;
    private double distanceParcourueKm;
    private String trajetResume;

    public VehiclePlanningDTO() {
        this.clients = new ArrayList<>();
    }

    public VehiclePlanningDTO(int idVehicule, String referenceVehicule, int placesTotales) {
        this.idVehicule = idVehicule;
        this.referenceVehicule = referenceVehicule;
        this.placesTotales = placesTotales;
        this.clients = new ArrayList<>();
        this.placesOccupees = 0;
    }

    
    public boolean ajouterClient(String nomClient, int nbPassager, String hotel, String heureArriveeHotel, int idReservation) {
        if (placesOccupees + nbPassager <= placesTotales) {
            ClientInfo client = new ClientInfo();
            client.setNomClient(nomClient);
            client.setNbPassager(nbPassager);
            client.setHotel(hotel);
            client.setHeureArriveeHotel(heureArriveeHotel);
            client.setIdReservation(idReservation);
            clients.add(client);
            placesOccupees += nbPassager;
            return true;
        }
        return false;
    }

   
    public boolean peutAccueillir(int nbPassager) {
        return placesOccupees + nbPassager <= placesTotales;
    }

   
    public int getPlacesRestantes() {
        return placesTotales - placesOccupees;
    }

    public int getIdVehicule() {
        return idVehicule;
    }

    public void setIdVehicule(int idVehicule) {
        this.idVehicule = idVehicule;
    }

    public String getReferenceVehicule() {
        return referenceVehicule;
    }

    public void setReferenceVehicule(String referenceVehicule) {
        this.referenceVehicule = referenceVehicule;
    }

    public String getDateHeureDepart() {
        return dateHeureDepart;
    }

    public void setDateHeureDepart(String dateHeureDepart) {
        this.dateHeureDepart = dateHeureDepart;
    }

    public String getDateHeureRetour() {
        return dateHeureRetour;
    }

    public void setDateHeureRetour(String dateHeureRetour) {
        this.dateHeureRetour = dateHeureRetour;
    }

    public List<ClientInfo> getClients() {
        return clients;
    }

    public void setClients(List<ClientInfo> clients) {
        this.clients = clients;
    }

    public LocalDateTime getHeureRetourParsed() {
        return heureRetourParsed;
    }

    public void setHeureRetourParsed(LocalDateTime heureRetourParsed) {
        this.heureRetourParsed = heureRetourParsed;
    }

    public int getPlacesOccupees() {
        return placesOccupees;
    }

    public void setPlacesOccupees(int placesOccupees) {
        this.placesOccupees = placesOccupees;
    }

    public int getPlacesTotales() {
        return placesTotales;
    }

    public void setPlacesTotales(int placesTotales) {
        this.placesTotales = placesTotales;
    }

    public double getDistanceParcourueKm() {
        return distanceParcourueKm;
    }

    public void setDistanceParcourueKm(double distanceParcourueKm) {
        this.distanceParcourueKm = distanceParcourueKm;
    }

    public String getTrajetResume() {
        return trajetResume;
    }

    public void setTrajetResume(String trajetResume) {
        this.trajetResume = trajetResume;
    }

}
