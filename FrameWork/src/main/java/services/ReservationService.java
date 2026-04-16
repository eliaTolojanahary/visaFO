package services;

import models.Lieu;
import models.Reservation;
import util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReservationService {

    public List<Lieu> getLieuxExceptIvato() throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "SELECT id, code, libelle FROM lieu WHERE code <> 'IVATO' ORDER BY libelle";
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
        }
        return lieux;
    }

    public boolean saveReservation(Reservation reservation) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sql = "INSERT INTO reservation (client, id_hotel, nb_passager, date_heure_depart) VALUES (?, ?, ?, ?::timestamp)";
            try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                stmt.setString(1, reservation.getClient());
                stmt.setInt(2, reservation.getIdHotel());
                stmt.setInt(3, reservation.getNbPassager());
                stmt.setString(4, reservation.getDateHeureDepart());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                    try (ResultSet rs = stmt.getGeneratedKeys()) {
                        if (rs.next()) {
                            reservation.setId(rs.getInt(1));
                        }
                    }
                }
            }
        }
        return success;
    }

    public List<Reservation> getAllReservations() throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        String sql = "SELECT r.id, r.client, r.id_hotel, h.nom AS hotel, r.nb_passager, r.date_heure_depart " +
            "FROM reservation r JOIN hotel h ON r.id_hotel = h.id " +
            "ORDER BY r.date_heure_depart";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Reservation r = new Reservation();
                r.setId(rs.getInt("id"));
                r.setClient(rs.getString("client"));
                r.setIdHotel(rs.getInt("id_hotel"));
                r.setHotel(rs.getString("hotel"));
                r.setNbPassager(rs.getInt("nb_passager"));
                r.setDateHeureDepart(String.valueOf(rs.getTimestamp("date_heure_depart")));
                reservations.add(r);
            }
        }
        return reservations;
    }
}