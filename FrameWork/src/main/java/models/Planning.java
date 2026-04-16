package models;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Classe métier pour la gestion de la planification des réservations
 */
public class Planning {
    
    /**
     * Récupère les réservations pour une date donnée
     */
    public static List<Reservation> getReservationsByDate(Connection conn, String date) throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        
        String sql = "SELECT r.id, r.client, r.id_hotel, h.nom as hotel, r.nb_passager, r.date_heure_depart " +
                 "FROM reservation r " +
                 "LEFT JOIN hotel h ON r.id_hotel = h.id " +
                     "WHERE DATE(r.date_heure_depart) = ?::date " +
                     "ORDER BY r.date_heure_depart";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, date);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                Reservation r = new Reservation();
                r.setId(rs.getInt("id"));
                r.setClient(rs.getString("client"));
                r.setIdHotel(rs.getInt("id_hotel"));
                r.setHotel(rs.getString("hotel"));
                r.setNbPassager(rs.getInt("nb_passager"));
                r.setDateHeureDepart(rs.getString("date_heure_depart"));
                reservations.add(r);
            }
        }
        
        return reservations;
    }
    
    /**
     * Récupère tous les lieux
     */
    public static List<Lieu> getAllLieux(Connection conn) throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        
        String sql = "SELECT id, code, libelle FROM lieu ORDER BY libelle";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Lieu l = new Lieu();
                l.setId(rs.getInt("id"));
                l.setCode(rs.getString("code"));
                l.setLibelle(rs.getString("libelle"));
                lieux.add(l);
            }
        }
        
        return lieux;
    }
    
    /**
     * Récupère toutes les distances
     */
    public static List<Distance> getAllDistances(Connection conn) throws SQLException {
        List<Distance> distances = new ArrayList<>();
        
        String sql = "SELECT d.id, d.from_lieu, d.to_lieu, d.km, " +
                     "l1.libelle as from_libelle, l2.libelle as to_libelle " +
                     "FROM distance d " +
                     "JOIN lieu l1 ON d.from_lieu = l1.id " +
                     "JOIN lieu l2 ON d.to_lieu = l2.id";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Distance d = new Distance();
                d.setId(rs.getInt("id"));
                d.setFromLieu(rs.getInt("from_lieu"));
                d.setToLieu(rs.getInt("to_lieu"));
                d.setKm(rs.getDouble("km"));
                d.setFromLieuLibelle(rs.getString("from_libelle"));
                d.setToLieuLibelle(rs.getString("to_libelle"));
                distances.add(d);
            }
        }
        
        return distances;
    }
    
    /**
     * Récupère tous les véhicules disponibles
     */
    public static List<Vehicule> getAllVehicules(Connection conn) throws SQLException {
        List<Vehicule> vehicules = new ArrayList<>();
        
        String sql = "SELECT id, reference, place, type_carburant, heure_disponibilite FROM vehicule ORDER BY place, type_carburant";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Vehicule v = new Vehicule();
                v.setId(rs.getInt("id"));
                v.setReference(rs.getString("reference"));
                v.setPlace(rs.getInt("place"));
                v.setTypeCarburant(rs.getString("type_carburant"));
                java.sql.Time heureDisp = rs.getTime("heure_disponibilite");
                if (heureDisp != null) v.setHeureDisponibilite(heureDisp.toLocalTime());
                vehicules.add(v);
            }
        }
        
        return vehicules;
    }
    
    /**
     * Récupère la configuration active du planning
     */
    public static PlanningConfig getActiveConfig(Connection conn) throws SQLException {
        String sql = "SELECT id, vitesse_moyenne, temps_attente, date_creation, is_active " +
                     "FROM planning_config " +
                     "WHERE is_active = true " +
                     "ORDER BY date_creation DESC LIMIT 1";
        
        try (PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            if (rs.next()) {
                return PlanningConfig.fromDatabase(
                    rs.getInt("id"),
                    rs.getDouble("vitesse_moyenne"),
                    rs.getInt("temps_attente"),
                    rs.getTimestamp("date_creation"),
                    rs.getBoolean("is_active")
                );
            }
        }
        
        // Config par défaut si aucune n'existe
        return PlanningConfig.fromDatabase(0, 40.0, 15, null, true);
    }
    
    /**
     * Calcule la distance entre deux lieux
     */
    public static double getDistanceEntreLieux(int lieu1, int lieu2, List<Distance> distances) {
        return Distance.getDistanceBetween(lieu1, lieu2, distances);
    }
}
