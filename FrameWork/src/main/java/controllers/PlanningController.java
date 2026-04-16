package controllers;

import annotation.ClasseAnnotation;
import annotation.GetMapping;
import annotation.MethodeAnnotation;
import annotation.PostMapping;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import models.*;
import modelview.ModelView;
import services.PlanningService;

@ClasseAnnotation("/planning")
public class PlanningController {
    
    private PlanningService planningService = new PlanningService();

    @MethodeAnnotation("/planning/config/form")
    @GetMapping
    public ModelView getFormPlanningConfig() {
        ModelView mv = new ModelView("/formPlanningConfig.jsp");
        
        try {
            PlanningConfig config = planningService.getActiveConfig();
            mv.addData("config", config);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement de la configuration: " + e.getMessage());
        }
        
        return mv;
    }
    
    @MethodeAnnotation("/planning/config/save")
    @PostMapping
    public ModelView savePlanningConfig(PlanningConfig config) {
        ModelView mv = new ModelView("/resultPlanningConfig.jsp");
        boolean success = false;
        
        try {
            success = planningService.savePlanningConfig(config);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("config", config);
        return mv;
    }
    
    @MethodeAnnotation("/planning/selection-date")
    @GetMapping
    public ModelView getFormSelectionDate() {
        ModelView mv = new ModelView("/formSelectionDatePlanning.jsp");
        
        try {
            PlanningConfig config = planningService.getActiveConfig();
            mv.addData("config", config);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement de la configuration: " + e.getMessage());
        }
        
        return mv;
    }
    
    @MethodeAnnotation("/planning/reservations-by-date")
    @PostMapping
    public ModelView getReservationsByDate(String datePlanning) {
        ModelView mv = new ModelView("/listReservationsByDate.jsp");
        String datePlanningNormalisee = planningService.normaliserDatePlanning(datePlanning);

        if (datePlanningNormalisee == null) {
            mv.addData("error", "Date invalide. Utiliser le format yyyy-MM-dd ou dd/MM/yyyy.");
            mv.addData("reservations", new ArrayList<Reservation>());
            mv.addData("count", 0);
            return mv;
        }
        
        try {
            List<Reservation> reservations = planningService.getReservationsByDate(datePlanningNormalisee);
            PlanningConfig config = planningService.getActiveConfig();
            Map<String, List<Reservation>> reservationsParCreneau = planningService.grouperReservationsParCreneau(
                reservations,
                config != null ? config.getTempsAttente() : 0
            );
            
            mv.addData("reservations", reservations);
            mv.addData("reservationsParCreneau", reservationsParCreneau);
            mv.addData("datePlanning", datePlanningNormalisee);
            mv.addData("config", config);
            mv.addData("count", reservations.size());
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des réservations: " + e.getMessage());
        }
        
        return mv;
    }
    
    @MethodeAnnotation("/planning/result")
    @PostMapping
    public ModelView getPlanningResult(String datePlanning) {
        ModelView mv = new ModelView("/resultPlanning.jsp");
        
        try {
            Map<String, Object> resultData = planningService.getPlanningResultData(datePlanning);
            
            if (resultData.containsKey("error")) {
                mv.addData("error", resultData.get("error"));
            } else {
                mv.addData("planningsParCreneauMap", resultData.get("planningsParCreneauMap"));
                mv.addData("unassignedParCreneauMap", resultData.get("unassignedParCreneauMap"));
                mv.addData("config", resultData.get("config"));
            }
            if (resultData.containsKey("datePlanningNormalisee")) {
                mv.addData("datePlanning", resultData.get("datePlanningNormalisee"));
            }

        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du calcul de la planification: " + e.getMessage());
        }
        
        return mv;
    }

    @MethodeAnnotation("/planning/lieux")
    @GetMapping
    public ModelView getAllLieux() {
        ModelView mv = new ModelView("/listLieux.jsp");
        
        try {
            List<Lieu> lieux = planningService.getAllLieux();
            mv.addData("lieux", lieux);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des lieux: " + e.getMessage());
        }
        
        return mv;
    }
    
    @MethodeAnnotation("/planning/distances")
    @GetMapping
    public ModelView getAllDistances() {
        ModelView mv = new ModelView("/listDistances.jsp");
        
        try {
            List<Distance> distances = planningService.getAllDistances();
            mv.addData("distances", distances);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des distances: " + e.getMessage());
        }
        
        return mv;
    }
    
    @MethodeAnnotation("/planning/vehicule-detail")
    @PostMapping
    public ModelView getVehiculePlanningInfo(int idVehicule, String datePlanning) {
        ModelView mv = new ModelView("/detailVehicule.jsp");
        
        try {
            Map<String, Object> resultData = planningService.getVehiculePlanningInfoData(idVehicule, datePlanning);

            if (resultData.containsKey("error")) {
                mv.addData("error", resultData.get("error"));
            }
                
            if (resultData.containsKey("vehicule")) mv.addData("vehicule", resultData.get("vehicule"));
            if (resultData.containsKey("datePlanning")) mv.addData("datePlanning", resultData.get("datePlanning"));
            if (resultData.containsKey("planning")) mv.addData("planning", resultData.get("planning"));
            if (resultData.containsKey("itineraire")) mv.addData("itineraire", resultData.get("itineraire"));
            if (resultData.containsKey("distanceTotale")) mv.addData("distanceTotale", resultData.get("distanceTotale"));
            if (resultData.containsKey("config")) mv.addData("config", resultData.get("config"));
            
        } catch (Exception e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors du chargement des détails: " + e.getMessage());
        }
        
        return mv;
    }
}
