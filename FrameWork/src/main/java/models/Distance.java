package models;

public class Distance {
    private int id;
    private int fromLieu;
    private int toLieu;
    private double km;
    
    // Pour faciliter l'affichage
    private String fromLieuLibelle;
    private String toLieuLibelle;
    
    public Distance() {
    }
    
    public Distance(int id, int fromLieu, int toLieu, double km) {
        this.id = id;
        this.fromLieu = fromLieu;
        this.toLieu = toLieu;
        this.km = km;
    }
    
    // Getters
    public int getId() {
        return id;
    }
    
    public int getFromLieu() {
        return fromLieu;
    }
    
    public int getToLieu() {
        return toLieu;
    }
    
    public double getKm() {
        return km;
    }
    
    public String getFromLieuLibelle() {
        return fromLieuLibelle;
    }
    
    public String getToLieuLibelle() {
        return toLieuLibelle;
    }
    
    // Setters
    public void setId(int id) {
        this.id = id;
    }
    
    public void setFromLieu(int fromLieu) {
        this.fromLieu = fromLieu;
    }
    
    public void setToLieu(int toLieu) {
        this.toLieu = toLieu;
    }
    
    public void setKm(double km) {
        this.km = km;
    }
    
    public void setFromLieuLibelle(String fromLieuLibelle) {
        this.fromLieuLibelle = fromLieuLibelle;
    }
    
    public void setToLieuLibelle(String toLieuLibelle) {
        this.toLieuLibelle = toLieuLibelle;
    }
    
    /**
     * Retourne la distance entre deux lieux (gère les couples symétriques)
     */
    public static double getDistanceBetween(int lieu1, int lieu2, java.util.List<Distance> distances) {
        for (Distance d : distances) {
            if ((d.fromLieu == lieu1 && d.toLieu == lieu2) || (d.fromLieu == lieu2 && d.toLieu == lieu1)) {
                return d.km;
            }
        }
        return 0.0;
    }
    
    @Override
    public String toString() {
        return "Distance{" +
                "id=" + id +
                ", fromLieu=" + fromLieu +
                ", toLieu=" + toLieu +
                ", km=" + km +
                '}';
    }
}
