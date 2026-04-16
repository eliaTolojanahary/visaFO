package models;

public class ClientInfo {
        private int idReservation;
        String nomClient;
        int nbPassager;
        private String hotel;
        String heureArriveeHotel;

        public int getIdReservation() {
            return idReservation;
        }

        public void setIdReservation(int idReservation) {
            this.idReservation = idReservation;
        }

        public String getNomClient() {
            return nomClient;
        }

        public void setNomClient(String nomClient) {
            this.nomClient = nomClient;
        }

        public int getNbPassager() {
            return nbPassager;
        }

        public void setNbPassager(int nbPassager) {
            this.nbPassager = nbPassager;
        }

        public String getHotel() {
            return hotel;
        }

        public void setHotel(String hotel) {
            this.hotel = hotel;
        }

        public String getHeureArriveeHotel() {
            return heureArriveeHotel;
        }

        public void setHeureArriveeHotel(String heureArriveeHotel) {
            this.heureArriveeHotel = heureArriveeHotel;
        }
    
    
}
