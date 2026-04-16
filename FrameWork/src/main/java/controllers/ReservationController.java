package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Lieu;
import models.Reservation;
import modelview.ModelView;
import services.ReservationService;

@ClasseAnnotation("/reservation")
public class ReservationController {
    
    private ReservationService reservationService = new ReservationService();
  
    @MethodeAnnotation("/reservation/form")
    @GetMapping
    public ModelView getFormReservation() {
        ModelView mv = new ModelView("/formReservation.jsp");
        try {
            List<Lieu> lieux = reservationService.getLieuxExceptIvato();
            mv.addData("lieux", lieux);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des lieux: " + e.getMessage());
        }
        return mv;
    }
    
   
    @MethodeAnnotation("/reservation/save")
    @PostMapping
    public ModelView saveReservation(Reservation reservation) {
        ModelView mv = new ModelView("/resultReservation.jsp");
        boolean success = false;
        
        try {
            success = reservationService.saveReservation(reservation);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("reservation", reservation);
        return mv;
    }

    @MethodeAnnotation("/reservation/list")
    @GetMapping
    public ModelView getAllReservations() {
        ModelView mv = new ModelView("/listReservationsByDate.jsp");
        List<Reservation> reservations = new ArrayList<>();
        mv.addData("reservationListPage", true);
        mv.addData("datePlanning", "");

        try {
            reservations = reservationService.getAllReservations();
        } catch (SQLException e) {
            System.err.println("==== ERREUR SQL dans getAllReservations ====");
            e.printStackTrace();
            mv.addData("error", "Erreur SQL: " + e.getMessage() + " | Cause: " + e.getCause());
        } catch (Exception e) {
            System.err.println("==== ERREUR GENERALE dans getAllReservations ====");
            e.printStackTrace();
            mv.addData("error", "Erreur: " + e.getClass().getName() + " - " + e.getMessage());
        }
        mv.addData("reservations", reservations);
        mv.addData("count", reservations.size());
        return mv;
    }
}
