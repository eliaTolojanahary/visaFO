package models;

public class ReservationEnrichi {
    public Reservation reservation;
    public Lieu lieuHotel;
    public double distanceFromAeroport;
    
    public ReservationEnrichi(Reservation reservation, Lieu lieuHotel, double distanceFromAeroport) {
        this.reservation = reservation;
        this.lieuHotel = lieuHotel;
        this.distanceFromAeroport = distanceFromAeroport;
    }
    
    public String getClient() {
        return reservation.getClient();
    }
    
    public int getNbPassager() {
        return reservation.getNbPassager();
    }
    
    public String getDateHeureDepart() {
        return reservation.getDateHeureDepart();
    }
    
    public Lieu getLieuHotel() {
        return lieuHotel;
    }
    
    public double getDistanceFromAeroport() {
        return distanceFromAeroport;
    }
    
    public void setLieuHotel(Lieu lieuHotel) {
        this.lieuHotel = lieuHotel;
    }
    
    public void setDistanceFromAeroport(double distanceFromAeroport) {
        this.distanceFromAeroport = distanceFromAeroport;
    }
    
    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
    }
}
    
    