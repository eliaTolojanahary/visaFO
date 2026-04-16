package controllers;

import annotation.MethodeAnnotation;
import annotation.GetMapping;
import annotation.PostMapping;
import annotation.ClasseAnnotation;
import annotation.RequestParam;
import modelview.ModelView;
import models.Vehicule;
import services.VehiculeService;
import java.sql.SQLException;
import java.util.List;

@ClasseAnnotation("/vehicule")
public class VehiculeController {
   
    private VehiculeService vehiculeService = new VehiculeService();

    @MethodeAnnotation("/vehicule/form")
    @GetMapping
    public ModelView getFormVehicule() {
        ModelView mv = new ModelView("/formVehicule.jsp");
        return mv;
    }
 
    @MethodeAnnotation("/vehicule/save")
    @PostMapping
    public ModelView saveVehicule(Vehicule vehicule) {
        ModelView mv = new ModelView("/resultVehicule.jsp");
        boolean success = false;
        
        try {
            success = vehiculeService.saveVehicule(vehicule);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de l'enregistrement: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("vehicule", vehicule);
        return mv;
    }
    

    @MethodeAnnotation("/vehicule/list")
    @GetMapping
    public ModelView listVehicules() {
        ModelView mv = new ModelView("/listVehicule.jsp");
        
        try {
            List<Vehicule> vehicules = vehiculeService.getAllVehicules();
            mv.addData("vehicules", vehicules);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la récupération des véhicules: " + e.getMessage());
        }
        
        return mv;
    }

    @MethodeAnnotation("/vehicule/edit")
    @GetMapping
    public ModelView editFormVehicule(@RequestParam("id") String idStr) {
        ModelView mv = new ModelView("/editVehicule.jsp");
        
        try {
            int id = Integer.parseInt(idStr);
            Vehicule vehicule = vehiculeService.getVehiculeById(id);
            
            if (vehicule != null) {
                mv.addData("vehicule", vehicule);
            } else {
                mv.addData("error", "Véhicule non trouvé");
            }
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la récupération du véhicule: " + e.getMessage());
        }
        
        return mv;
    }
    

    @MethodeAnnotation("/vehicule/update")
    @PostMapping
    public ModelView updateVehicule(@RequestParam("id") String idStr, Vehicule vehicule) {
        ModelView mv = new ModelView("/resultVehicule.jsp");
        boolean success = false;
        
        try {
            int id = Integer.parseInt(idStr);
            vehicule.setId(id);

            success = vehiculeService.updateVehicule(vehicule);
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la mise à jour: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("vehicule", vehicule);
        mv.addData("action", "update");
        return mv;
    }
    
    @MethodeAnnotation("/vehicule/delete")
    @GetMapping
    public ModelView deleteVehicule(@RequestParam("id") String idStr) {
        ModelView mv = new ModelView("/resultVehicule.jsp");
        boolean success = false;
        
        try {
            int id = Integer.parseInt(idStr);
            success = vehiculeService.deleteVehicule(id);
        } catch (NumberFormatException e) {
            mv.addData("error", "ID invalide");
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addData("error", "Erreur lors de la suppression: " + e.getMessage());
        }
        
        mv.addData("success", success);
        mv.addData("action", "delete");
        return mv;
    }
}
