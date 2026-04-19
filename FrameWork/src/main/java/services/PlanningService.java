package services;

import java.sql.*;
import java.util.*;
import models.*;
import util.DatabaseConnection;

public class PlanningService {

    public PlanningConfig getActiveConfig() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getActiveConfig(conn);
        }
    }

    public boolean savePlanningConfig(PlanningConfig config) throws SQLException {
        boolean success = false;
        try (Connection conn = DatabaseConnection.getConnection()) {
            String sqlUpdate = "UPDATE planning_config SET is_active = false WHERE is_active = true";
            try (PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdate)) {
                stmtUpdate.executeUpdate();
            }
            
            String sql = "INSERT INTO planning_config (vitesse_moyenne, temps_attente, is_active) VALUES (?, ?, true)";
            try (PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                stmt.setDouble(1, config.getVitesseMoyenne());
                stmt.setInt(2, config.getTempsAttente());
                
                int rowsAffected = stmt.executeUpdate();
                if (rowsAffected > 0) {
                    success = true;
                    try (ResultSet rs = stmt.getGeneratedKeys()) {
                        if (rs.next()) {
                            config.setId(rs.getInt(1));
                        }
                    }
                }
            }
        }
        return success;
    }

    public List<Lieu> getAllLieux() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllLieux(conn);
        }
    }

    public List<Distance> getAllDistances() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllDistances(conn);
        }
    }

    public List<Reservation> getReservationsByDate(String datePlanningNormalisee) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getReservationsByDate(conn, datePlanningNormalisee);
        }
    }

    public Map<String, Object> getPlanningResultData(String datePlanning) throws Exception {
        Map<String, Object> result = new HashMap<>();
        String datePlanningNormalisee = normaliserDatePlanning(datePlanning);
        result.put("datePlanningNormalisee", datePlanningNormalisee);

        if (datePlanningNormalisee == null) {
            result.put("error", "Date invalide. Utiliser le format yyyy-MM-dd ou dd/MM/yyyy.");
            return result;
        }

        List<Reservation> reservations = getReservationsByDate(datePlanningNormalisee);
        List<Vehicule> vehicules = getAllVehicules();
        PlanningConfig config = getActiveConfig();
        List<Distance> distances = getAllDistances();
        List<Lieu> lieux = getAllLieux();

        Lieu aeroport = lieux.stream()
            .filter(l -> l.getCode().equals("IVATO"))
            .findFirst()
            .orElse(null);

        if (aeroport == null) {
            result.put("error", "Erreur: Aeroport IVATO non trouve");
            return result;
        }

        List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
        for (Reservation r : reservations) {
            Lieu lieuHotel = trouverLieuPourReservation(r, lieux);
            if (lieuHotel != null) {
                double distanceKm = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, Math.max(0.0, distanceKm)));
            }
        }

        reservationsEnrichies.sort((r1, r2) -> {
            int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
            if (cmpPassagers != 0) return cmpPassagers;
            return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
        });

        Map<String, List<VehiclePlanningDTO>> planningsParCreneauMap = new LinkedHashMap<>();
        Map<String, List<ReservationDTO>> unassignedParCreneauMap = new LinkedHashMap<>();

        int pasMinutes = config != null && config.getTempsAttente() > 0 ? config.getTempsAttente() : 30;
        Map<String, List<ReservationEnrichi>> reservationsParCreneau = new LinkedHashMap<>();
        List<VehiclePlanningDTO> planningsTousLesCreneaux = new ArrayList<>(); 

        for (ReservationEnrichi r : reservationsEnrichies) {
            java.time.LocalDateTime dateHeure = parserDateHeureReservation(r.reservation.getDateHeureDepart());
            String cleCreneau = "Inconnu";
            if (dateHeure != null) {
                int totalMinutes = dateHeure.getHour() * 60 + dateHeure.getMinute();
                int debutCreneauMinutes = (totalMinutes / pasMinutes) * pasMinutes;
                int finCreneauMinutes = debutCreneauMinutes + pasMinutes;
                cleCreneau = formaterCreneau(debutCreneauMinutes, finCreneauMinutes);
            }
            reservationsParCreneau.computeIfAbsent(cleCreneau, k -> new ArrayList<>()).add(r);
        }

        List<Map.Entry<String, List<ReservationEnrichi>>> creneauxOrdonnes = new ArrayList<>(reservationsParCreneau.entrySet());
        creneauxOrdonnes.sort((e1, e2) -> Integer.compare(extraireDebutCreneauMinutes(e1.getKey()), extraireDebutCreneauMinutes(e2.getKey())));

        List<ReservationEnrichi> reservationsReportees = new ArrayList<>();

        for (int indexCreneau = 0; indexCreneau < creneauxOrdonnes.size(); indexCreneau++) {
            Map.Entry<String, List<ReservationEnrichi>> entry = creneauxOrdonnes.get(indexCreneau);
            boolean dernierCreneau = indexCreneau == creneauxOrdonnes.size() - 1;
            String creneau = entry.getKey();
            boolean regroupementEnCours = entry.getValue() != null && !entry.getValue().isEmpty();

            List<VehiclePlanningDTO> planningsCurrentCreneau = new ArrayList<>();
            List<ReservationDTO> unassignedCurrentCreneau = new ArrayList<>();
            Set<VehiclePlanningDTO> planningsRetourDepartImmediat = new HashSet<>();

            // --- DEBUT LOGIC RETOUR VEHICULE NON ASSIGNE ---
            List<ReservationEnrichi> unassignedHandled = new ArrayList<>();
            List<ReservationEnrichi> normalHandled = new ArrayList<>();
            
            if (!reservationsReportees.isEmpty()) {
                List<Vehicule> vehiculesTries = new ArrayList<>(vehicules);
                final List<VehiclePlanningDTO> history = planningsTousLesCreneaux;

                int debutCreneauMin = extraireDebutCreneauMinutes(creneau);
                int finCreneauMin = debutCreneauMin + pasMinutes;

                // Copie de travail pour les non-assignés
                List<ReservationEnrichi> unassignedWorkList = new ArrayList<>(reservationsReportees);
                
                // Trier les réservations non assignées par priorité : NbPassager DESC, Distance ASC
                unassignedWorkList.sort((r1, r2) -> {
                    int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                    if (cmpPassagers != 0) return cmpPassagers;
                    return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
                });

                // Prioriser les véhicules qui matchent le mieux la réservation non-assignée prioritaire.
                int passagersPrioritaires = unassignedWorkList.get(0).getNbPassager();
                vehiculesTries.sort((v1, v2) -> {
                    int diff1 = v1.getPlace() >= passagersPrioritaires
                        ? v1.getPlace() - passagersPrioritaires
                        : Integer.MAX_VALUE / 2 + (passagersPrioritaires - v1.getPlace());
                    int diff2 = v2.getPlace() >= passagersPrioritaires
                        ? v2.getPlace() - passagersPrioritaires
                        : Integer.MAX_VALUE / 2 + (passagersPrioritaires - v2.getPlace());

                    int cmpDiff = Integer.compare(diff1, diff2);
                    if (cmpDiff != 0) {
                        return cmpDiff;
                    }

                    java.time.LocalTime t1 = history.stream()
                        .filter(p -> p.getIdVehicule() == v1.getId())
                        .map(this::extraireHeureRetourPlanning)
                        .filter(java.util.Objects::nonNull)
                        .max(java.time.LocalTime::compareTo)
                        .orElse(v1.getHeureDisponibilite() != null ? v1.getHeureDisponibilite() : java.time.LocalTime.MIN);
                    java.time.LocalTime t2 = history.stream()
                        .filter(p -> p.getIdVehicule() == v2.getId())
                        .map(this::extraireHeureRetourPlanning)
                        .filter(java.util.Objects::nonNull)
                        .max(java.time.LocalTime::compareTo)
                        .orElse(v2.getHeureDisponibilite() != null ? v2.getHeureDisponibilite() : java.time.LocalTime.MIN);
                    return t1.compareTo(t2);
                });
                
                for (Vehicule v : vehiculesTries) {
                    if (unassignedWorkList.isEmpty()) break;

                    // Vérifier si le véhicule est déjà utilisé dans le futur (dans planningsTousLesCreneaux)
                    // (Ici on suppose que planningsTousLesCreneaux est chronologique et qu'on est à la "fin" de l'historique connu)
                    
                    java.time.LocalTime heureRetour = null;
                    java.util.Optional<java.time.LocalTime> optHeureRetour = history.stream()
                        .filter(p -> p.getIdVehicule() == v.getId())
                        .map(this::extraireHeureRetourPlanning)
                        .filter(java.util.Objects::nonNull)
                        .max(java.time.LocalTime::compareTo);
                    
                    if (optHeureRetour.isPresent()) {
                        heureRetour = optHeureRetour.get();
                    } else {
                        // Inclure aussi les véhicules sans historique: utiliser leur heure de disponibilité initiale.
                        heureRetour = v.getHeureDisponibilite() != null ? v.getHeureDisponibilite() : java.time.LocalTime.MIN;
                    }

                    int returnMin = heureRetour.getHour() * 60 + heureRetour.getMinute();
                    
                    // Si le véhicule est dispo (déjà rentré) ou rentre PENDANT ce créneau
                    if (returnMin <= finCreneauMin) {
                        // Mais attention, s'il rentre à 8h50 et le créneau est 8h00-8h30 (c'est pas possible car on avance chronologiquement)
                        // Si le créneau est 8h30-9h00, et retour à 8h50, C'EST BON.
                        // Si retour à 8h10, et créneau 8h30-9h00. Il est dispo à 8h10.
                        // On doit prendre MAX(heureRetour, debutCreneau?) 
                        // La règle dit : "A partir de son temps de retour". 
                        // Donc si retour 8h50, départ 8h50.
                        // Si retour 8h10 (dispo avant créneau), on peut dire départ "immédiat" (mais on est dans la boucle 8h30).
                        // On va assumer qu'on peut créer un intervalle qui commence AVANT le créneau actuel si nécessaire pour rattraper le retard.
                        
                        // CORRECTION : Si le retour est AVANT le début du créneau (ex: retour 8h10, créneau 08h30-09h00),
                        // Le départ doit se faire au début du créneau actuel (08h30), sinon on crée un planning dans le passé du créneau.
                        // SAUF si "immédiat" veut dire rattraper le temps perdu. 
                        // Mais généralement, on attend le début du créneau de prise en charge pour lequel on a des résas (qui sont peut-être parties de 08h00 mais on les traite ici).
                        // Si on a des résas NON ASSIGNEES, elles sont dispo DEPUIS LONGTEMPS. Donc dès que la voiture arrive, on part.
                        
                        // Donc : dateDepart = HeureRetour. (Même si c'est 08h10).
                        // Mais pour l'affichage et la logique d'intervalle, il faut être cohérent.
                        
                        // Si returnMin < debutCreneauMin, cela signifie que la voiture était prête AVANT ce créneau.
                        // Pourquoi n'a-t-elle pas été utilisée avant? Peut-être parce que par chance elle se libère ou on redécouvre sa dispo.
                        // Pour les "non assignés", ils attendent. Donc départ dès que voiture la.
                        // -> dateDepart = Math.max(HeureRetour, DebutCreneau) ?
                        // Si le client attend depuis 8h00 et la voiture arrive à 8h10. On part à 8h10.
                        // Si le client attend depuis 8h00 et la voiture arrive à 7h50 (mais on traite le créneau 8h00 car pas vu avant?).
                        // On va garder dateDepart = heureRetour pour l'instant, c'est le plus logique pour "dès que dispo".
                        // MAIS si heureRetour est vraiment trop vieux (ex: hier), on clamp au début du créneau ? Non ici c'est du meme jour.
                        
                        // FIX: Utiliser la date du planning, pas LocalDate.now() qui peut être different du jour planifié
                         java.time.LocalDate jourPlanning = java.time.LocalDate.now();
                         if (datePlanningNormalisee != null) {
                             try {
                                 jourPlanning = java.time.LocalDate.parse(datePlanningNormalisee);
                             } catch (Exception e) { /* fallback today */ }
                         }
                        // Création du planning
                        VehiclePlanningDTO planningVehicule = new VehiclePlanningDTO(v.getId(), v.getReference(), v.getPlace());
                        java.time.LocalDateTime dateDepart = java.time.LocalDateTime.of(jourPlanning, heureRetour); 
                        
                        // Assigner les passagers
                        List<ReservationEnrichi> aAssigner = new ArrayList<>();
                        List<ReservationEnrichi> unassignedForThisVehicle = new ArrayList<>();
                        
                        // Remplir avec les non-assignés (priorité)
                        int placesDispo = v.getPlace();
                        Iterator<ReservationEnrichi> it = unassignedWorkList.iterator();
                        while (it.hasNext() && placesDispo > 0) {
                            ReservationEnrichi r = it.next();
                            int nbPassagers = r.getNbPassager();
                            
                            if (nbPassagers <= placesDispo) {
                                unassignedForThisVehicle.add(r);
                                placesDispo -= nbPassagers;
                                it.remove();
                                unassignedHandled.add(r);
                            } else {
                                // SPLIT: Prendre ce qui rentre, laisser le reste
                                int toTake = placesDispo;
                                int remaining = nbPassagers - toTake;
                                
                                // Créer la partie qui embarque
                                Reservation partialRes = copierReservationAvecNbPassager(r.reservation, toTake);
                                ReservationEnrichi partialEnriched = new ReservationEnrichi(
                                    partialRes, 
                                    r.lieuHotel, 
                                    r.getDistanceFromAeroport()
                                );
                                unassignedForThisVehicle.add(partialEnriched);
                                
                                // Mettre à jour la réservation originale avec le reste
                                r.reservation.setNbPassager(remaining);
                                // On ne l'ajoute PAS à unassignedHandled car le reste doit encore être traité plus tard
                                
                                placesDispo = 0; // Véhicule plein
                            }
                        }

                        if (!unassignedForThisVehicle.isEmpty()) {
                            planningVehicule.setClients(new ArrayList<>()); // Init list
                            for (ReservationEnrichi r : unassignedForThisVehicle) {
                                ajouterClientAuVehicule(planningVehicule, r, config, aeroport, distances, lieux, dateDepart);
                            }
                            
                            boolean isFull = (placesDispo == 0); // Simpliste, ou seuil? "Si le vehicule est plein"
                            
                            java.time.LocalTime startInterval = heureRetour;
                            java.time.LocalTime endInterval = isFull ? heureRetour : heureRetour.plusMinutes(pasMinutes);
                            
                            // Si PAS PLEIN, on essaye de combler avec les réservations NORMALES du créneau
                            if (!isFull) {
                                // Chercher dans entry.getValue() (les normaux) ceux qui sont compatibles
                                // Compatible = HeureResa >= StartInterval && HeureResa <= EndInterval
                                for (ReservationEnrichi rNormal : entry.getValue()) {
                                    if (placesDispo <= 0) break;
                                    if (normalHandled.contains(rNormal)) continue;

                                    java.time.LocalDateTime rTime = parserDateHeureReservation(rNormal.reservation.getDateHeureDepart());
                                    if (rTime != null) {
                                        java.time.LocalTime rt = rTime.toLocalTime();
                                        if (!rt.isBefore(startInterval) && !rt.isAfter(endInterval)) {
                                            if (rNormal.getNbPassager() <= placesDispo) {
                                                ajouterClientAuVehicule(planningVehicule, rNormal, config, aeroport, distances, lieux, dateDepart);
                                                placesDispo -= rNormal.getNbPassager();
                                                normalHandled.add(rNormal);
                                            }
                                        }
                                    }
                                }
                            }
                            
                             // Recalcul placesDispo REEL après ajout potentiel des normaux
                            placesDispo = planningVehicule.getPlacesRestantes();
                            isFull = (placesDispo == 0);
                            
                            // SI FINALEMENT PLEIN (après ajout normaux ou initialement), on force l'intervalle à 0 minute (départ immédiat)
                            if (isFull) {
                                endInterval = heureRetour;
                            }
                            
                            // Finalisation du planning
                            // Recalculer trajet pour avoir heure retour correcte
                            recalculerHorairesVehicule(planningVehicule, config, aeroport, distances, lieux, dateDepart);
                            
                            // Ajouter aux listes globales
                            planningsTousLesCreneaux.add(planningVehicule);

                            int startMin = startInterval.getHour() * 60 + startInterval.getMinute();
                            int endMin = endInterval.getHour() * 60 + endInterval.getMinute();

                            boolean overlapAvecCreneauEnCours = intervallesSeChevauchentInclusif(
                                startMin,
                                endMin,
                                debutCreneauMin,
                                finCreneauMin
                            );

                            boolean integrerAuCreneauEnCours = regroupementEnCours
                                && ((returnMin >= debutCreneauMin && returnMin <= finCreneauMin)
                                    || overlapAvecCreneauEnCours);

                            if (integrerAuCreneauEnCours) {
                                // Un regroupement est deja en cours: on integre ce retour au creneau actif.
                                planningsCurrentCreneau.add(planningVehicule);
                                if (isFull) {
                                    // Vehicule de retour plein: depart immediat conserve, sans recalage de regroupement.
                                    planningsRetourDepartImmediat.add(planningVehicule);
                                }
                            } else {
                                // Sinon, on cree un creneau dynamique "Retour".
                                String dynamicKey = formaterCreneau(startMin, endMin) + " (Retour)";

                                planningsParCreneauMap.computeIfAbsent(dynamicKey, k -> new ArrayList<>()).add(planningVehicule);

                                // Snapshot des non-assignes restants au moment de creation du creneau retour.
                                List<ReservationDTO> unassignedSnapshot = new ArrayList<>();
                                for (ReservationEnrichi re : unassignedWorkList) {
                                    unassignedSnapshot.add(new ReservationDTO(re.reservation));
                                }
                                unassignedParCreneauMap.put(dynamicKey, unassignedSnapshot);
                            }
                        }
                    }
                }
            }
            // --- FIN LOGIC RETOUR VEHICULE NON ASSIGNE ---

            List<ReservationEnrichi> resDansCreneau = new ArrayList<>();
            // IDs des réservations non assignées
            final Set<Integer> unassignedIds = new HashSet<>();
            if (!reservationsReportees.isEmpty()) {
                resDansCreneau.addAll(reservationsReportees);// Ajoute seulement ceux qui restent
                // Retirer ceux qu'on vient de traiter (unassignedHandled a été retiré de la copie de travail, mais pas de l'original ici encore)
                resDansCreneau.removeAll(unassignedHandled); 
                for (ReservationEnrichi r : resDansCreneau) {
                    unassignedIds.add(r.reservation.getId()); // Capturer les ID des non-assignés restants
                }
                reservationsReportees.clear();
            }
            // Ajouter les normaux qui n'ont PAS été pris par la logique dynamique
            List<ReservationEnrichi> normauxRestants = new ArrayList<>(entry.getValue());
            normauxRestants.removeAll(normalHandled);
            resDansCreneau.addAll(normauxRestants);
            
            List<ReservationEnrichi> reservationsOriginalesCreneau = new ArrayList<>(resDansCreneau);

            // TRI PRINCIPAL: Priorité Non Assigné > Best-Fit Potential > Nb Passager DESC > Distance ASC
            resDansCreneau.sort((r1, r2) -> {
                boolean u1 = unassignedIds.contains(r1.reservation.getId());
                boolean u2 = unassignedIds.contains(r2.reservation.getId());
                if (u1 != u2) return u1 ? -1 : 1; // Les non-assignés passent avant
                
                // Entre réservations de même type, trier par best-fit potential
                // Trouver véhicule optimal pour chacune
                int p1 = r1.reservation.getNbPassager();
                int p2 = r2.reservation.getNbPassager();
                
                int bestFit1 = vehicules.stream()
                    .filter(v -> v.getPlace() >= p1)
                    .mapToInt(v -> v.getPlace() - p1)
                    .min().orElse(Integer.MAX_VALUE);
                int bestFit2 = vehicules.stream()
                    .filter(v -> v.getPlace() >= p2)
                    .mapToInt(v -> v.getPlace() - p2)
                    .min().orElse(Integer.MAX_VALUE);
                
                // Prioriser celle avec meilleur fit (plus petit écart)
                int cmpBestFit = Integer.compare(bestFit1, bestFit2);
                if (cmpBestFit != 0) return cmpBestFit;
                
                // Si égal best-fit, trier par nombre de passagers DESC (plus grands d'abord)
                int cmpPassagers = Integer.compare(p2, p1);
                if (cmpPassagers != 0) return cmpPassagers;
                
                return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
            });

            while (!resDansCreneau.isEmpty()) {
                ReservationEnrichi r = resDansCreneau.remove(0);
                r = affecterAuxPlanningsExistantsAvecDivision(
                    planningsCurrentCreneau,
                    r,
                    config,
                    aeroport,
                    distances,
                    lieux
                );
                if (r == null) {
                    continue;
                }
                java.time.LocalDateTime heureReservation = parserDateHeureReservation(r.reservation.getDateHeureDepart());
                
                java.time.LocalDateTime heureDispoMaxTemp = heureReservation;
                if (heureReservation != null && creneau.contains("-")) {
                    try {
                        String finStr = creneau.split("-")[1].trim();
                        java.time.LocalTime finTime = java.time.LocalTime.parse(finStr);
                        heureDispoMaxTemp = java.time.LocalDateTime.of(heureReservation.toLocalDate(), finTime);
                    } catch (Exception e) {}
                }
                final java.time.LocalDateTime heureDispoMax = heureDispoMaxTemp;

                Vehicule vehicule = trouverVehiculeOptimal(vehicules, planningsTousLesCreneaux, r.reservation, heureDispoMax);

                if (vehicule != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                        vehicule.getId(), 
                        vehicule.getReference(), 
                        vehicule.getPlace()
                    );
                    
                    int nbPassagers = r.getNbPassager();
                    int placesDispo = vehicule.getPlace();

                    if (nbPassagers > placesDispo) {
                         // Must split
                         int toTake = placesDispo;
                         int remaining = nbPassagers - toTake;
                         
                         Reservation partialRes = copierReservationAvecNbPassager(r.reservation, toTake);
                         ReservationEnrichi partialEnriched = new ReservationEnrichi(partialRes, r.lieuHotel, r.getDistanceFromAeroport());
                         
                         ajouterClientAuVehicule(nouveauPlanning, partialEnriched, config, aeroport, distances, lieux, null);
                         planningsCurrentCreneau.add(nouveauPlanning);
                         planningsTousLesCreneaux.add(nouveauPlanning);
                         
                         // Update r for next steps
                         r.reservation.setNbPassager(remaining);
                         resDansCreneau.add(0, r); // Put back to beginning to be processed again
                         continue;
                    }
                    
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux, null);
                    planningsCurrentCreneau.add(nouveauPlanning);
                    planningsTousLesCreneaux.add(nouveauPlanning);

                    // Remplir avec les réservations ASSIGNÉES uniquement
                    // Les non-assignées restent en tête de liste pour priorité absolue
                    List<ReservationEnrichi> assigneesRestantes = new ArrayList<>();
                    List<ReservationEnrichi> nonAssigneesRestantes = new ArrayList<>();
                    for (ReservationEnrichi res : resDansCreneau) {
                        if (unassignedIds.contains(res.reservation.getId())) {
                            nonAssigneesRestantes.add(res);
                        } else {
                            assigneesRestantes.add(res);
                        }
                    }
                    
                    remplirPlacesRestantesOptimal(nouveauPlanning, assigneesRestantes, config, aeroport, distances, lieux, r, null);
                    
                    // Reconstituer la liste: non-assignées d'abord, puis assignées restantes
                    resDansCreneau.clear();
                    resDansCreneau.addAll(nonAssigneesRestantes);
                    resDansCreneau.addAll(assigneesRestantes);
                } else {
                    java.util.List<Vehicule> vehiculesDisponibles = vehicules.stream()
                        .filter(v -> estVehiculeDisponiblePourReservation(v, planningsTousLesCreneaux, heureDispoMax))
                        .collect(java.util.stream.Collectors.toList());

                    DivisionReservationResult division = diviserReservation(r, vehiculesDisponibles, planningsTousLesCreneaux);
                    boolean auMoinsUneAssignation = false;

                    // Séparer assignées et non-assignées une fois avant la boucle
                    List<ReservationEnrichi> assigneesDiv = new ArrayList<>();
                    List<ReservationEnrichi> nonAssigneesDiv = new ArrayList<>();
                    for (ReservationEnrichi res : resDansCreneau) {
                        if (unassignedIds.contains(res.reservation.getId())) {
                            nonAssigneesDiv.add(res);
                        } else {
                            assigneesDiv.add(res);
                        }
                    }

                    for (ReservationEnrichi reservationDivisee : division.getReservationsAssignees()) {
                        Vehicule vehiculeDivise = trouverVehiculeOptimal(vehiculesDisponibles,
                            reservationDivisee.getNbPassager(), planningsTousLesCreneaux);
                        if (vehiculeDivise == null) {
                            continue;
                        }

                        vehiculesDisponibles.removeIf(v -> v.getId() == vehiculeDivise.getId());

                        VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(
                            vehiculeDivise.getId(),
                            vehiculeDivise.getReference(),
                            vehiculeDivise.getPlace()
                        );
                        ajouterClientAuVehicule(nouveauPlanning, reservationDivisee, config, aeroport, distances, lieux, null);
                        planningsCurrentCreneau.add(nouveauPlanning);
                        planningsTousLesCreneaux.add(nouveauPlanning);
                        auMoinsUneAssignation = true;
                        
                        remplirPlacesRestantesOptimal(nouveauPlanning, assigneesDiv, config, aeroport, distances, lieux, r, null);
                    }

                    // Reconstituer: non-assignées d'abord (pour priorité)
                    resDansCreneau.clear();
                    resDansCreneau.addAll(nonAssigneesDiv);
                    resDansCreneau.addAll(assigneesDiv);

                    int passagersRestants = division.getPassagersRestants();
                    if (!auMoinsUneAssignation && passagersRestants == 0) {
                        passagersRestants = r.getNbPassager();
                    }

                    if (passagersRestants > 0) {
                        Reservation reservationRestante = copierReservationAvecNbPassager(r.reservation, passagersRestants);
                        ReservationEnrichi enrichieRestante = new ReservationEnrichi(
                            reservationRestante,
                            r.lieuHotel,
                            r.getDistanceFromAeroport()
                        );

                        if (!dernierCreneau) {
                            reservationsReportees.add(enrichieRestante);
                        }
                        unassignedCurrentCreneau.add(new ReservationDTO(reservationRestante));
                    }
                }
            }

            java.time.LocalDateTime heureDepartRegroupement = determinerHeureDepartRegroupement(
                planningsCurrentCreneau,
                reservationsOriginalesCreneau,
                planningsTousLesCreneaux,
                vehicules
            );
            if (heureDepartRegroupement != null) {
                for (VehiclePlanningDTO planningVehicule : planningsCurrentCreneau) {
                    if (planningsRetourDepartImmediat.contains(planningVehicule)) {
                        continue;
                    }
                    recalculerHorairesVehicule(planningVehicule, config, aeroport, distances, lieux, heureDepartRegroupement);
                }
            }

            planningsCurrentCreneau.sort((p1, p2) -> Integer.compare(p1.getIdVehicule(), p2.getIdVehicule()));
            planningsParCreneauMap.put(creneau, planningsCurrentCreneau);
            unassignedParCreneauMap.put(creneau, unassignedCurrentCreneau);
        }

        result.put("planningsParCreneauMap", planningsParCreneauMap);
        result.put("unassignedParCreneauMap", unassignedParCreneauMap);
        try {
            sauvegarderAssignements(datePlanningNormalisee, planningsParCreneauMap);
            result.put("assignementSaved", true);
        } catch (SQLException e) {
            throw new SQLException("Echec sauvegarde assignement: " + e.getMessage(), e);
        }
        result.put("config", config);
        
        return result;
    }

    private void sauvegarderAssignements(String datePlanningNormalisee,
                                          Map<String, List<VehiclePlanningDTO>> planningsParCreneauMap) throws SQLException {
        if (datePlanningNormalisee == null || datePlanningNormalisee.trim().isEmpty() || planningsParCreneauMap == null) {
            return;
        }

        String sqlCreateTable = "CREATE TABLE IF NOT EXISTS assignement ("
            + "id SERIAL PRIMARY KEY, "
            + "id_reservation INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE, "
            + "id_vehicule INTEGER NOT NULL REFERENCES vehicule(id) ON DELETE CASCADE, "
            + "nb_passager_assigne INTEGER NOT NULL CHECK (nb_passager_assigne > 0), "
            + "date_planning DATE NOT NULL, "
            + "creneau VARCHAR(30), "
            + "heure_depart VARCHAR(5), "
            + "heure_retour VARCHAR(5), "
            + "date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
            + "CONSTRAINT uq_assignement UNIQUE (date_planning, id_reservation, id_vehicule, creneau)"
            + ")";

        String sqlDelete = "DELETE FROM assignement WHERE date_planning = ?";
        String sqlInsert = "INSERT INTO assignement (id_reservation, id_vehicule, nb_passager_assigne, date_planning, creneau, heure_depart, heure_retour) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection()) {
            boolean previousAutoCommit = conn.getAutoCommit();
            conn.setAutoCommit(false);
            try {
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute(sqlCreateTable);
                }

                try (PreparedStatement deleteStmt = conn.prepareStatement(sqlDelete)) {
                    deleteStmt.setDate(1, java.sql.Date.valueOf(datePlanningNormalisee));
                    deleteStmt.executeUpdate();
                }

                try (PreparedStatement insertStmt = conn.prepareStatement(sqlInsert)) {
                    for (Map.Entry<String, List<VehiclePlanningDTO>> entry : planningsParCreneauMap.entrySet()) {
                        String creneau = entry.getKey();
                        List<VehiclePlanningDTO> plannings = entry.getValue();
                        if (plannings == null) {
                            continue;
                        }

                        for (VehiclePlanningDTO planning : plannings) {
                            if (planning == null || planning.getClients() == null) {
                                continue;
                            }

                            for (ClientInfo client : planning.getClients()) {
                                if (client == null || client.getIdReservation() <= 0 || client.getNbPassager() <= 0) {
                                    continue;
                                }

                                insertStmt.setInt(1, client.getIdReservation());
                                insertStmt.setInt(2, planning.getIdVehicule());
                                insertStmt.setInt(3, client.getNbPassager());
                                insertStmt.setDate(4, java.sql.Date.valueOf(datePlanningNormalisee));
                                insertStmt.setString(5, creneau);
                                insertStmt.setString(6, planning.getDateHeureDepart());
                                insertStmt.setString(7, planning.getDateHeureRetour());
                                insertStmt.addBatch();
                            }
                        }
                    }
                    insertStmt.executeBatch();
                }

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(previousAutoCommit);
            }
        }
    }

    public Map<String, Object> getVehiculePlanningInfoData(int idVehicule, String datePlanning) throws Exception {
        Map<String, Object> result = new HashMap<>();

        List<Reservation> reservations = getReservationsByDate(datePlanning);
        List<Vehicule> vehicules = getAllVehicules();
        PlanningConfig config = getActiveConfig();
        List<Distance> distances = getAllDistances();
        List<Lieu> lieux = getAllLieux();

        Lieu aeroport = lieux.stream()
            .filter(l -> l.getCode().equals("IVATO"))
            .findFirst()
            .orElse(null);

        if (aeroport == null) {
            result.put("error", "Erreur: Aeroport IVATO non trouve");
            return result;
        }

        Vehicule vehicule = vehicules.stream()
            .filter(v -> v.getId() == idVehicule)
            .findFirst()
            .orElse(null);

        if (vehicule == null) {
            result.put("error", "Vehicule non trouve");
            return result;
        }

        List<ReservationEnrichi> reservationsEnrichies = new ArrayList<>();
        for (Reservation r : reservations) {
            Lieu lieuHotel = trouverLieuPourReservation(r, lieux);
            if (lieuHotel != null) {
                double distanceFromAeroport = Distance.getDistanceBetween(aeroport.getId(), lieuHotel.getId(), distances);
                reservationsEnrichies.add(new ReservationEnrichi(r, lieuHotel, Math.max(0.0, distanceFromAeroport)));
            }
        }

        reservationsEnrichies.sort((r1, r2) -> {
            int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
            if (cmpPassagers != 0) return cmpPassagers;
            return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
        });

        List<VehiclePlanningDTO> plannings = new ArrayList<>();

        int pasMinutes = config != null && config.getTempsAttente() > 0 ? config.getTempsAttente() : 30;
        Map<String, List<ReservationEnrichi>> reservationsParCreneau = new LinkedHashMap<>();

        for (ReservationEnrichi r : reservationsEnrichies) {
            java.time.LocalDateTime dateHeure = parserDateHeureReservation(r.reservation.getDateHeureDepart());
            String cleCreneau = "Inconnu";
            if (dateHeure != null) {
                int totalMinutes = dateHeure.getHour() * 60 + dateHeure.getMinute();
                int debutCreneauMinutes = (totalMinutes / pasMinutes) * pasMinutes;
                int finCreneauMinutes = debutCreneauMinutes + pasMinutes;
                cleCreneau = formaterCreneau(debutCreneauMinutes, finCreneauMinutes);
            }
            reservationsParCreneau.computeIfAbsent(cleCreneau, k -> new ArrayList<>()).add(r);
        }

        List<Map.Entry<String, List<ReservationEnrichi>>> creneauxOrdonnes = new ArrayList<>(reservationsParCreneau.entrySet());
        creneauxOrdonnes.sort((e1, e2) -> Integer.compare(extraireDebutCreneauMinutes(e1.getKey()), extraireDebutCreneauMinutes(e2.getKey())));
        List<ReservationEnrichi> reservationsReportees = new ArrayList<>();

        for (Map.Entry<String, List<ReservationEnrichi>> entry : creneauxOrdonnes) {
            List<ReservationEnrichi> resDansCreneau = new ArrayList<>();
            if (!reservationsReportees.isEmpty()) {
                resDansCreneau.addAll(reservationsReportees);
                reservationsReportees.clear();
            }
            resDansCreneau.addAll(entry.getValue());
            List<ReservationEnrichi> reservationsOriginalesCreneau = new ArrayList<>(resDansCreneau);
            List<VehiclePlanningDTO> planningsCurrentCreneau = new ArrayList<>();

            while (!resDansCreneau.isEmpty()) {
                ReservationEnrichi r = resDansCreneau.remove(0);
                r = affecterAuxPlanningsExistantsAvecDivision(
                    planningsCurrentCreneau,
                    r,
                    config,
                    aeroport,
                    distances,
                    lieux
                );
                if (r == null) {
                    continue;
                }
                java.time.LocalDateTime heureReservation = parserDateHeureReservation(r.reservation.getDateHeureDepart());
                
                java.time.LocalDateTime heureDispoMaxTemp = heureReservation;
                if (heureReservation != null && entry.getKey().contains("-")) {
                    try {
                        String finStr = entry.getKey().split("-")[1].trim();
                        java.time.LocalTime finTime = java.time.LocalTime.parse(finStr);
                        heureDispoMaxTemp = java.time.LocalDateTime.of(heureReservation.toLocalDate(), finTime);
                    } catch (Exception e) {}
                }
                final java.time.LocalDateTime heureDispoMax = heureDispoMaxTemp;

                List<VehiclePlanningDTO> planningsDeReference = new ArrayList<>(plannings);
                planningsDeReference.addAll(planningsCurrentCreneau);
                Vehicule v = trouverVehiculeOptimal(vehicules, planningsDeReference, r.reservation, heureDispoMax);

                if (v != null) {
                    VehiclePlanningDTO nouveauPlanning = new VehiclePlanningDTO(v.getId(), v.getReference(), v.getPlace());
                    ajouterClientAuVehicule(nouveauPlanning, r, config, aeroport, distances, lieux, null);
                    planningsCurrentCreneau.add(nouveauPlanning);

                    remplirPlacesRestantesOptimal(nouveauPlanning, resDansCreneau, config, aeroport, distances, lieux, r, null);
                } else {
                    java.util.List<Vehicule> vehiculesDisponibles = vehicules.stream()
                        .filter(vd -> estVehiculeDisponiblePourReservation(vd, planningsDeReference, heureDispoMax))
                        .collect(java.util.stream.Collectors.toList());
                    DivisionReservationResult division = diviserReservation(r, vehiculesDisponibles, planningsDeReference);

                    boolean auMoinsUneAssignation = false;
                    for (ReservationEnrichi reservationDivisee : division.getReservationsAssignees()) {
                        Vehicule vehiculeDivise = trouverVehiculeOptimal(vehiculesDisponibles,
                            reservationDivisee.getNbPassager(), planningsDeReference);
                        if (vehiculeDivise == null) {
                            continue;
                        }

                        vehiculesDisponibles.removeIf(vd -> vd.getId() == vehiculeDivise.getId());

                        VehiclePlanningDTO nouveauPlanningDivise = new VehiclePlanningDTO(
                            vehiculeDivise.getId(),
                            vehiculeDivise.getReference(),
                            vehiculeDivise.getPlace()
                        );
                        ajouterClientAuVehicule(nouveauPlanningDivise, reservationDivisee, config, aeroport, distances, lieux, null);
                        planningsCurrentCreneau.add(nouveauPlanningDivise);
                        auMoinsUneAssignation = true;

                        remplirPlacesRestantesOptimal(nouveauPlanningDivise, resDansCreneau, config, aeroport, distances, lieux, r, null);
                    }

                    int passagersRestants = division.getPassagersRestants();
                    if (!auMoinsUneAssignation && passagersRestants == 0) {
                        passagersRestants = r.getNbPassager();
                    }

                    if (passagersRestants > 0) {
                        Reservation reservationRestante = copierReservationAvecNbPassager(r.reservation, passagersRestants);
                        reservationsReportees.add(new ReservationEnrichi(
                            reservationRestante,
                            r.lieuHotel,
                            r.getDistanceFromAeroport()
                        ));
                    }
                }
            }

            java.time.LocalDateTime heureDepartRegroupement = determinerHeureDepartRegroupement(
                planningsCurrentCreneau,
                reservationsOriginalesCreneau,
                plannings,
                vehicules
            );
            if (heureDepartRegroupement != null) {
                for (VehiclePlanningDTO planningVehicule : planningsCurrentCreneau) {
                    recalculerHorairesVehicule(planningVehicule, config, aeroport, distances, lieux, heureDepartRegroupement);
                }
            }

            plannings.addAll(planningsCurrentCreneau);
        }

        VehiclePlanningDTO planning = plannings.stream()
            .filter(p -> p.getIdVehicule() == idVehicule)
            .findFirst()
            .orElse(null);

        if (planning == null) {
            result.put("error", "Aucun client assigne e ce vehicule pour cette date");
            result.put("vehicule", vehicule);
            result.put("datePlanning", datePlanning);
            return result;
        }

        List<EtapeItineraire> itineraire = calculerItineraireDetaille(planning, config, aeroport, distances, lieux);

        double distanceTotale = itineraire.stream()
            .mapToDouble(EtapeItineraire::getDistance)
            .sum();

        result.put("vehicule", vehicule);
        result.put("planning", planning);
        result.put("itineraire", itineraire);
        result.put("distanceTotale", distanceTotale);
        result.put("datePlanning", datePlanning);
        result.put("config", config);

        return result;
    }

    public Map<String, List<Reservation>> grouperReservationsParCreneau(List<Reservation> reservations, int intervalleMinutes) {
        Map<String, List<Reservation>> groupes = new LinkedHashMap<>();
        int pasMinutes = intervalleMinutes > 0 ? intervalleMinutes : 30;

        if (reservations == null || reservations.isEmpty()) {
            return groupes;
        }

        List<Reservation> reservationsTriees = new ArrayList<>(reservations);
        reservationsTriees.sort((r1, r2) -> {
            java.time.LocalDateTime d1 = parserDateHeureReservation(r1.getDateHeureDepart());
            java.time.LocalDateTime d2 = parserDateHeureReservation(r2.getDateHeureDepart());
            if (d1 == null && d2 == null) return 0;
            if (d1 == null) return 1;
            if (d2 == null) return -1;
            return d1.compareTo(d2);
        });

        for (Reservation reservation : reservationsTriees) {
            java.time.LocalDateTime dateHeure = parserDateHeureReservation(reservation.getDateHeureDepart());
            String cleCreneau;

            if (dateHeure == null) {
                cleCreneau = "Horaire invalide";
            } else {
                int totalMinutes = dateHeure.getHour() * 60 + dateHeure.getMinute();
                int debutCreneauMinutes = (totalMinutes / pasMinutes) * pasMinutes;
                int finCreneauMinutes = debutCreneauMinutes + pasMinutes;
                cleCreneau = formaterCreneau(debutCreneauMinutes, finCreneauMinutes);
            }

            groupes.computeIfAbsent(cleCreneau, k -> new ArrayList<>()).add(reservation);
        }

        return groupes;
    }

    public String normaliserDatePlanning(String datePlanning) {
        if (datePlanning == null) {
            return null;
        }

        String valeur = datePlanning.trim();
        if (valeur.isEmpty()) {
            return null;
        }

        try {
            java.time.LocalDate d = java.time.LocalDate.parse(valeur);
            return d.toString();
        } catch (Exception ignored) {
        }

        try {
            java.time.format.DateTimeFormatter f = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
            java.time.LocalDate d = java.time.LocalDate.parse(valeur, f);
            return d.toString();
        } catch (Exception ignored) {
        }

        return null;
    }

    public void ajouterClientAuVehicule(VehiclePlanningDTO planning, ReservationEnrichi r, 
                                         PlanningConfig config, Lieu aeroport, 
                                         List<Distance> distances, List<Lieu> lieux, java.time.LocalDateTime heureDepartForcee) {
        try {
            java.time.LocalDateTime dateHeureArriveeClient = java.time.LocalDateTime.parse(
                r.reservation.getDateHeureDepart().replace(" ", "T")
            );
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            String heureArriveeStr = formatter.format(dateHeureArriveeClient);
            
            planning.ajouterClient(
                r.reservation.getClient(),
                r.reservation.getNbPassager(),
                r.lieuHotel != null ? r.lieuHotel.getLibelle() : r.reservation.getHotel(),
                heureArriveeStr,
                r.reservation.getId()
            );
            
            recalculerHorairesVehicule(planning, config, aeroport, distances, lieux, heureDepartForcee);
            
        } catch (java.time.format.DateTimeParseException e) {
            System.err.println("Erreur de parsing de la date: " + e.getMessage());
        }
    }

    public void recalculerHorairesVehicule(VehiclePlanningDTO planning, PlanningConfig config,
                                            Lieu aeroport, List<Distance> distances, List<Lieu> lieux, java.time.LocalDateTime heureDepartForcee) {
        if (planning.getClients().isEmpty()) return;
        
        List<ClientInfo> clients = planning.getClients();
        List<ClientInfo> clientsTries = new ArrayList<>(clients);
        clientsTries.sort((c1, c2) -> {
            Lieu h1 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c1.getHotel().toLowerCase()) 
                          || c1.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            Lieu h2 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c2.getHotel().toLowerCase()) 
                          || c2.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            
            if (h1 == null || h2 == null) return 0;
            double dist1 = Distance.getDistanceBetween(aeroport.getId(), h1.getId(), distances);
            double dist2 = Distance.getDistanceBetween(aeroport.getId(), h2.getId(), distances);
            return Double.compare(dist1, dist2);
        });
        
        Lieu lieuPrecedent = aeroport;
        double tempsTotal = 0; 
        double distanceTotaleKm = 0.0;
        StringBuilder trajet = new StringBuilder();
        String codeAeroport = aeroport.getCode() != null ? aeroport.getCode() : "IVATO";
        trajet.append(codeAeroport);
        
        for (ClientInfo client : clientsTries) {
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                double distance = Distance.getDistanceBetween(lieuPrecedent.getId(), lieuHotel.getId(), distances);
                double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
                double tempsTrajet = distance / vitesse; 
                tempsTotal += tempsTrajet;
                distanceTotaleKm += distance;
                trajet.append(" -> ").append(lieuHotel.getCode() != null ? lieuHotel.getCode() : lieuHotel.getLibelle());
                lieuPrecedent = lieuHotel;
            }
        }
        
        double distanceRetour = Distance.getDistanceBetween(lieuPrecedent.getId(), aeroport.getId(), distances);
        double vitesse = (config != null && config.getVitesseMoyenne() > 0) ? config.getVitesseMoyenne() : 40.0;
        double tempsRetour = distanceRetour / vitesse;
        tempsTotal += tempsRetour;
        planning.setDistanceParcourueKm(distanceTotaleKm);
        planning.setTrajetResume(trajet.toString());
        
        try {
            java.time.LocalDateTime heureDepartVehicule = heureDepartForcee;

            if (heureDepartVehicule == null) {
                for (ClientInfo client : clients) {
                    String heureArrivee = client.getHeureArriveeHotel();
                    String[] parts = heureArrivee.split(":");
                    java.time.LocalDateTime heureClient = java.time.LocalDate.now()
                        .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));

                    if (heureDepartVehicule == null || heureClient.isAfter(heureDepartVehicule)) {
                        heureDepartVehicule = heureClient;
                    }
                }
            }

            if (heureDepartVehicule == null) {
                return;
            }
            
            long heures = (long) tempsTotal;
            long minutes = (long) ((tempsTotal - heures) * 60);
            java.time.LocalDateTime heureRetourVehicule = heureDepartVehicule.plusHours(heures).plusMinutes(minutes);
            
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
            planning.setDateHeureDepart(formatter.format(heureDepartVehicule));
            planning.setDateHeureRetour(formatter.format(heureRetourVehicule));
            planning.setHeureRetourParsed(heureRetourVehicule);
        } catch (Exception e) {
            System.err.println("Erreur parsing heure de depart: " + e.getMessage());
        }
    }

    public void remplirPlacesRestantesOptimal(VehiclePlanningDTO planning, 
                                                List<ReservationEnrichi> reservationsRestantes,
                                                PlanningConfig config, Lieu aeroport, 
                                                List<Distance> distances, List<Lieu> lieux,
                                                ReservationEnrichi reservationReferenceFenetre,
                                                java.time.LocalDateTime heureDepartForcee) {
        boolean peutAjouterDautres = true;
        
        while (peutAjouterDautres && planning.getPlacesRestantes() > 0 && !reservationsRestantes.isEmpty()) {
            peutAjouterDautres = false;

            int placesDisponibles = planning.getPlacesRestantes();
            int indexMeilleurCandidat = -1;
            int meilleurRemplissage = -1;
            int meilleureProximite = Integer.MAX_VALUE;
            double meilleureDistance = Double.MAX_VALUE;

            // Priorite:
            // 1) maximiser le remplissage reel du vehicule (min(nbPassagers, placesDisponibles))
            // 2) en cas d'egalite, choisir la reservation la plus proche des places restantes
            //    (ex: reste=5, candidats 6 et 7 -> choisir 6)
            // 3) en dernier, choisir la plus proche de l'aeroport
            for (int i = 0; i < reservationsRestantes.size(); i++) {
                ReservationEnrichi candidat = reservationsRestantes.get(i);
                int nbPassagers = candidat.reservation.getNbPassager();
                int remplissage = Math.min(nbPassagers, placesDisponibles);
                int proximite = Math.abs(nbPassagers - placesDisponibles);
                double distance = candidat.getDistanceFromAeroport();

                if (remplissage > meilleurRemplissage
                    || (remplissage == meilleurRemplissage && proximite < meilleureProximite)
                    || (remplissage == meilleurRemplissage && proximite == meilleureProximite && distance < meilleureDistance)) {
                    indexMeilleurCandidat = i;
                    meilleurRemplissage = remplissage;
                    meilleureProximite = proximite;
                    meilleureDistance = distance;
                }
            }

            if (indexMeilleurCandidat == -1 || placesDisponibles <= 0) {
                break;
            }

            ReservationEnrichi meilleurCandidat = reservationsRestantes.remove(indexMeilleurCandidat);
            int nbPassagersCandidat = meilleurCandidat.getNbPassager();

            if (nbPassagersCandidat <= placesDisponibles) {
                ajouterClientAuVehicule(planning, meilleurCandidat, config, aeroport, distances, lieux, heureDepartForcee);
                peutAjouterDautres = true;
            } else {
                Reservation reservationPourVehicule = copierReservationAvecNbPassager(meilleurCandidat.reservation, placesDisponibles);
                ReservationEnrichi enrichiePartielle = new ReservationEnrichi(
                    reservationPourVehicule,
                    meilleurCandidat.lieuHotel,
                    meilleurCandidat.getDistanceFromAeroport()
                );

                ajouterClientAuVehicule(planning, enrichiePartielle, config, aeroport, distances, lieux, heureDepartForcee);

                int passagersRestants = nbPassagersCandidat - placesDisponibles;
                Reservation reliquat = copierReservationAvecNbPassager(meilleurCandidat.reservation, passagersRestants);
                ReservationEnrichi enrichieReliquat = new ReservationEnrichi(
                    reliquat,
                    meilleurCandidat.lieuHotel,
                    meilleurCandidat.getDistanceFromAeroport()
                );
                reservationsRestantes.add(enrichieReliquat);

                reservationsRestantes.sort((r1, r2) -> {
                    int cmpPassagers = Integer.compare(r2.reservation.getNbPassager(), r1.reservation.getNbPassager());
                    if (cmpPassagers != 0) return cmpPassagers;
                    return Double.compare(r1.getDistanceFromAeroport(), r2.getDistanceFromAeroport());
                });

                peutAjouterDautres = true;
            }
        }
    }

    public boolean estCompatibleFenetreHoraire(Reservation reservationReference,
                                                Reservation reservationCandidate,
                                                PlanningConfig config) {
        if (reservationReference == null || reservationCandidate == null || config == null) {
            return true;
        }

        java.time.LocalDateTime heureReference = parserDateHeureReservation(reservationReference.getDateHeureDepart());
        java.time.LocalDateTime heureCandidate = parserDateHeureReservation(reservationCandidate.getDateHeureDepart());

        if (heureReference == null || heureCandidate == null) {
            return true;
        }

        int tempsAttenteMinutes = Math.max(0, config.getTempsAttente());
        java.time.LocalDateTime borneFin = heureReference.plusMinutes(tempsAttenteMinutes);

        return !heureCandidate.isBefore(heureReference) && !heureCandidate.isAfter(borneFin);
    }

    public java.time.LocalDateTime parserDateHeureReservation(String dateHeure) {
        if (dateHeure == null || dateHeure.trim().isEmpty()) {
            return null;
        }

        try {
            return java.time.LocalDateTime.parse(dateHeure.replace(" ", "T"));
        } catch (Exception e) {
            return null;
        }
    }

    public java.time.LocalDateTime determinerHeureDepartRegroupement(List<VehiclePlanningDTO> planningsCreneau,
                                                                       List<ReservationEnrichi> reservationsDuCreneau,
                                                                       List<VehiclePlanningDTO> planningsPrecedents,
                                                                       List<Vehicule> vehicules) {
        if (planningsCreneau == null || planningsCreneau.isEmpty() || reservationsDuCreneau == null || reservationsDuCreneau.isEmpty()) {
            return null;
        }

        java.util.Map<Integer, java.time.LocalDateTime> reservationParHeure = new java.util.HashMap<>();
        for (ReservationEnrichi reservationEnrichie : reservationsDuCreneau) {
            if (reservationEnrichie == null || reservationEnrichie.reservation == null) {
                continue;
            }
            java.time.LocalDateTime dateReservation = parserDateHeureReservation(
                reservationEnrichie.reservation.getDateHeureDepart()
            );
            if (dateReservation != null) {
                reservationParHeure.put(reservationEnrichie.reservation.getId(), dateReservation);
            }
        }

        java.time.LocalDateTime derniereHeureAssignee = null;
        for (VehiclePlanningDTO planningVehicule : planningsCreneau) {
            if (planningVehicule == null || planningVehicule.getClients() == null) {
                continue;
            }
            for (ClientInfo clientInfo : planningVehicule.getClients()) {
                java.time.LocalDateTime heureClientAssignee = reservationParHeure.get(clientInfo.getIdReservation());
                if (heureClientAssignee != null && (derniereHeureAssignee == null || heureClientAssignee.isAfter(derniereHeureAssignee))) {
                    derniereHeureAssignee = heureClientAssignee;
                }
            }
        }

        // Vérifier si un véhicule du créneau actuel est revenu d'un trajet précédent
        // et a un temps de retour plus tardif que la dernière réservation.
        if (derniereHeureAssignee != null) {
            java.time.LocalDate dateActuelle = derniereHeureAssignee.toLocalDate();
            for (VehiclePlanningDTO planningVehicule : planningsCreneau) {
                int idVehicule = planningVehicule.getIdVehicule();
                
                // Chercher l'heure de disponibilité initiale
                java.time.LocalDateTime heureDispo = null;
                if (vehicules != null) {
                    Vehicule vehicule = vehicules.stream().filter(v -> v.getId() == idVehicule).findFirst().orElse(null);
                    if (vehicule != null && vehicule.getHeureDisponibilite() != null) {
                        try {
                            heureDispo = java.time.LocalDateTime.of(dateActuelle, vehicule.getHeureDisponibilite());
                        } catch (Exception e) {}
                    }
                }

                // Chercher le dernier retour parmi les plannings précédents de ce véhicule
                java.time.LocalDateTime dernierRetourVehicule = heureDispo;
                if (planningsPrecedents != null) {
                    for (VehiclePlanningDTO pastPlanning : planningsPrecedents) {
                        if (pastPlanning.getIdVehicule() == idVehicule && pastPlanning != planningVehicule) {
                            java.time.LocalTime rt = extraireHeureRetourPlanning(pastPlanning);
                            if (rt != null) {
                                java.time.LocalDateTime returnTime = java.time.LocalDateTime.of(dateActuelle, rt);
                                if (dernierRetourVehicule == null || returnTime.isAfter(dernierRetourVehicule)) {
                                    dernierRetourVehicule = returnTime;
                                }
                            }
                        }
                    }
                }

                // Si le véhicule est disponible/retourné après la dernière réservation, on repousse l'heure de départ
                if (dernierRetourVehicule != null && dernierRetourVehicule.isAfter(derniereHeureAssignee)) {
                    derniereHeureAssignee = dernierRetourVehicule;
                }
            }
        }

        return derniereHeureAssignee;
    }

    public Lieu trouverLieuPourReservation(Reservation reservation, List<Lieu> lieux) {
        if (reservation == null || lieux == null || lieux.isEmpty()) {
            return null;
        }

        String nomHotel = reservation.getHotel();
        if (nomHotel == null || nomHotel.trim().isEmpty()) {
            return lieux.stream()
                .filter(l -> l.getId() == reservation.getIdHotel())
                .findFirst()
                .orElse(null);
        }

        Lieu lieuParNom = lieux.stream()
            .filter(l -> l.getLibelle().toLowerCase().contains(nomHotel.toLowerCase())
                      || nomHotel.toLowerCase().contains(l.getLibelle().toLowerCase()))
            .findFirst()
            .orElse(null);

        if (lieuParNom != null) {
            return lieuParNom;
        }

        return lieux.stream()
            .filter(l -> l.getId() == reservation.getIdHotel())
            .findFirst()
            .orElse(null);
    }

    public String formaterCreneau(int debutMinutes, int finMinutes) {
        int debutHeure = (debutMinutes / 60) % 24;
        int debutMinute = debutMinutes % 60;
        int finHeure = (finMinutes / 60) % 24;
        int finMinute = finMinutes % 60;

        return String.format("%02d:%02d - %02d:%02d", debutHeure, debutMinute, finHeure, finMinute);
    }

    public int extraireDebutCreneauMinutes(String creneau) {
        if (creneau == null || !creneau.contains("-")) {
            return Integer.MAX_VALUE;
        }

        try {
            String debut = creneau.split("-")[0].trim();
            String[] hm = debut.split(":");
            int h = Integer.parseInt(hm[0].trim());
            int m = Integer.parseInt(hm[1].trim());
            return (h * 60) + m;
        } catch (Exception e) {
            return Integer.MAX_VALUE;
        }
    }

    private boolean intervallesSeChevauchentInclusif(int debutA, int finA, int debutB, int finB) {
        int minA = Math.min(debutA, finA);
        int maxA = Math.max(debutA, finA);
        int minB = Math.min(debutB, finB);
        int maxB = Math.max(debutB, finB);
        return minA <= maxB && maxA >= minB;
    }

    public Vehicule trouverVehiculeOptimal(List<Vehicule> tousVehicules,
                                            List<VehiclePlanningDTO> planningsExistants,
                                            Reservation reservationCandidate,
                                            java.time.LocalDateTime heureDepartPrevue) {
        int nbPassagers = reservationCandidate != null ? reservationCandidate.getNbPassager() : 0;

        List<Vehicule> vehiculesDisponibles = tousVehicules.stream()
            .filter(v -> estVehiculeDisponiblePourReservation(v, planningsExistants, heureDepartPrevue))
            .collect(java.util.stream.Collectors.toList());

        return trouverVehiculeOptimal(vehiculesDisponibles, nbPassagers, planningsExistants);
    }

    public ReservationEnrichi affecterAuxPlanningsExistantsAvecDivision(
            List<VehiclePlanningDTO> planningsExistantsCreneau,
            ReservationEnrichi reservation,
            PlanningConfig config,
            Lieu aeroport,
            List<Distance> distances,
            List<Lieu> lieux) {
        if (reservation == null || reservation.reservation == null) {
            return null;
        }

        int passagersRestants = Math.max(0, reservation.getNbPassager());
        if (passagersRestants == 0 || planningsExistantsCreneau == null || planningsExistantsCreneau.isEmpty()) {
            return reservation;
        }

        List<VehiclePlanningDTO> planningsAvecPlaces = new ArrayList<>();
        for (VehiclePlanningDTO planning : planningsExistantsCreneau) {
            if (planning != null && planning.getPlacesRestantes() > 0) {
                planningsAvecPlaces.add(planning);
            }
        }

        while (passagersRestants > 0 && !planningsAvecPlaces.isEmpty()) {
            final int passagersCourants = passagersRestants;

            VehiclePlanningDTO planning = planningsAvecPlaces.stream()
                .min((p1, p2) -> {
                    int diff1 = p1.getPlacesRestantes() >= passagersCourants
                        ? p1.getPlacesRestantes() - passagersCourants
                        : Integer.MAX_VALUE / 2 + (passagersCourants - p1.getPlacesRestantes());
                    int diff2 = p2.getPlacesRestantes() >= passagersCourants
                        ? p2.getPlacesRestantes() - passagersCourants
                        : Integer.MAX_VALUE / 2 + (passagersCourants - p2.getPlacesRestantes());

                    int cmpDiff = Integer.compare(diff1, diff2);
                    if (cmpDiff != 0) {
                        return cmpDiff;
                    }

                    return Integer.compare(p1.getIdVehicule(), p2.getIdVehicule());
                })
                .orElse(null);

            if (planning == null) {
                break;
            }

            int aAffecter = Math.min(passagersRestants, planning.getPlacesRestantes());
            if (aAffecter <= 0) {
                planningsAvecPlaces.remove(planning);
                continue;
            }

            Reservation reservationPartielle = copierReservationAvecNbPassager(reservation.reservation, aAffecter);
            ReservationEnrichi enrichiePartielle = new ReservationEnrichi(
                reservationPartielle,
                reservation.lieuHotel,
                reservation.getDistanceFromAeroport()
            );

            ajouterClientAuVehicule(planning, enrichiePartielle, config, aeroport, distances, lieux, null);
            passagersRestants -= aAffecter;

            if (planning.getPlacesRestantes() <= 0) {
                planningsAvecPlaces.remove(planning);
            }
        }

        if (passagersRestants <= 0) {
            return null;
        }

        Reservation reliquat = copierReservationAvecNbPassager(reservation.reservation, passagersRestants);
        return new ReservationEnrichi(reliquat, reservation.lieuHotel, reservation.getDistanceFromAeroport());
    }

    public boolean estVehiculeDisponiblePourReservation(Vehicule vehicule,
                                                         List<VehiclePlanningDTO> planningsExistants,
                                                         java.time.LocalDateTime dateHeureReservation) {
        if (dateHeureReservation == null) {
            return true;
        }
        
        if (vehicule.getHeureDisponibilite() != null) {
            if (dateHeureReservation.toLocalTime().isBefore(vehicule.getHeureDisponibilite())) {
                return false;
            }
        }

        if (planningsExistants == null || planningsExistants.isEmpty()) {
            return true;
        }

        List<VehiclePlanningDTO> planningsVehicule = planningsExistants.stream()
            .filter(p -> p.getIdVehicule() == vehicule.getId())
            .collect(java.util.stream.Collectors.toList());

        if (planningsVehicule.isEmpty()) {
            return true;
        }

        java.time.LocalTime dernierRetour = planningsVehicule.stream()
            .map(this::extraireHeureRetourPlanning)
            .filter(h -> h != null)
            .max(java.time.LocalTime::compareTo)
            .orElse(null);

        if (dernierRetour == null) {
            return false;
        }

        return !dernierRetour.isAfter(dateHeureReservation.toLocalTime());
    }

    public java.time.LocalTime extraireHeureRetourPlanning(VehiclePlanningDTO planning) {
        if (planning == null) {
            return null;
        }

        if (planning.getHeureRetourParsed() != null) {
            return planning.getHeureRetourParsed().toLocalTime();
        }

        String heureRetour = planning.getDateHeureRetour();
        if (heureRetour == null || heureRetour.trim().isEmpty()) {
            return null;
        }

        try {
            java.time.LocalTime h = java.time.LocalTime.parse(heureRetour);
            return h;
        } catch (Exception e) {
            return null;
        }
    }

    public Vehicule trouverVehiculeOptimal(List<Vehicule> vehiculesDisponibles, int nbPassagers, List<VehiclePlanningDTO> planningsExistants) {
        java.util.Map<Integer, Long> compteurCourses = construireCompteurCourses(planningsExistants);
        return choisirVehiculeSelonPriorites(vehiculesDisponibles, nbPassagers, compteurCourses, false);
    }

    public DivisionReservationResult diviserReservation(ReservationEnrichi reservation,
                                                        List<Vehicule> vehiculesDisponibles,
                                                        List<VehiclePlanningDTO> planningsExistants) {
        DivisionReservationResult result = new DivisionReservationResult();
        if (reservation == null || reservation.reservation == null) {
            return result;
        }

        int passagersRestants = Math.max(0, reservation.getNbPassager());
        if (passagersRestants == 0 || vehiculesDisponibles == null || vehiculesDisponibles.isEmpty()) {
            result.setPassagersRestants(passagersRestants);
            return result;
        }

        List<Vehicule> vehiculesTries = new ArrayList<>(vehiculesDisponibles);
        java.util.Map<Integer, Long> compteurCourses = construireCompteurCourses(planningsExistants);

        while (passagersRestants > 0 && !vehiculesTries.isEmpty()) {
            Vehicule vehiculeChoisi = choisirVehiculeSelonPriorites(
                vehiculesTries,
                passagersRestants,
                compteurCourses,
                true
            );
            if (vehiculeChoisi == null) {
                break;
            }

            int placesDisponibles = Math.max(0, vehiculeChoisi.getPlace());
            if (placesDisponibles == 0) {
                break;
            }

            int passagersAffectes = Math.min(passagersRestants, placesDisponibles);
            Reservation reservationPartielle = copierReservationAvecNbPassager(reservation.reservation, passagersAffectes);
            result.getReservationsAssignees().add(new ReservationEnrichi(
                reservationPartielle,
                reservation.lieuHotel,
                reservation.getDistanceFromAeroport()
            ));

            passagersRestants -= passagersAffectes;
            vehiculesTries.removeIf(v -> v.getId() == vehiculeChoisi.getId());
        }

        result.setPassagersRestants(passagersRestants);
        return result;
    }

    public java.util.Map<Integer, Long> construireCompteurCourses(List<VehiclePlanningDTO> planningsExistants) {
        java.util.Map<Integer, Long> compteurCourses = new java.util.HashMap<>();
        if (planningsExistants == null) {
            return compteurCourses;
        }

        for (VehiclePlanningDTO planning : planningsExistants) {
            compteurCourses.put(planning.getIdVehicule(), compteurCourses.getOrDefault(planning.getIdVehicule(), 0L) + 1L);
        }
        return compteurCourses;
    }

    public Vehicule choisirVehiculeSelonPriorites(List<Vehicule> vehiculesDisponibles,
                                                  int nbPassagers,
                                                  java.util.Map<Integer, Long> compteurCourses,
                                                  boolean autoriserPartiel) {
        if (vehiculesDisponibles == null || vehiculesDisponibles.isEmpty()) {
            return null;
        }

        List<Vehicule> candidatsPlein = vehiculesDisponibles.stream()
            .filter(v -> v.getPlace() >= nbPassagers)
            .collect(java.util.stream.Collectors.toList());

        List<Vehicule> candidatsBase = new ArrayList<>();
        boolean affectationComplete = !candidatsPlein.isEmpty();
        if (affectationComplete) {
            candidatsBase.addAll(candidatsPlein);
        } else if (autoriserPartiel) {
            candidatsBase.addAll(vehiculesDisponibles);
        } else {
            return null;
        }

        long meilleureMetric = affectationComplete
            ? candidatsBase.stream().mapToLong(v -> (long) v.getPlace() - nbPassagers).min().orElse(Long.MAX_VALUE)
            : candidatsBase.stream().mapToLong(Vehicule::getPlace).max().orElse(0L);

        List<Vehicule> candidatsProximite = candidatsBase.stream()
            .filter(v -> affectationComplete
                ? ((long) v.getPlace() - nbPassagers) == meilleureMetric
                : (long) v.getPlace() == meilleureMetric)
            .collect(java.util.stream.Collectors.toList());

        long minCourses = candidatsProximite.stream()
            .mapToLong(v -> compteurCourses.getOrDefault(v.getId(), 0L))
            .min()
            .orElse(0L);

        List<Vehicule> candidatsMoinsCourses = candidatsProximite.stream()
            .filter(v -> compteurCourses.getOrDefault(v.getId(), 0L) == minCourses)
            .collect(java.util.stream.Collectors.toList());

        List<Vehicule> diesels = candidatsMoinsCourses.stream()
            .filter(v -> "diesel".equalsIgnoreCase(v.getTypeCarburant()))
            .collect(java.util.stream.Collectors.toList());

        List<Vehicule> finalistes = diesels.isEmpty() ? candidatsMoinsCourses : diesels;
        if (finalistes.isEmpty()) {
            return null;
        }

        return finalistes.stream()
            .min((v1, v2) -> {
                int cmpPlace = Integer.compare(v1.getPlace(), v2.getPlace());
                if (cmpPlace != 0) {
                    return cmpPlace;
                }
                return Integer.compare(v1.getId(), v2.getId());
            })
            .orElse(null);
    }

    public Reservation copierReservationAvecNbPassager(Reservation source, int nbPassagers) {
        Reservation copie = new Reservation();
        if (source == null) {
            return copie;
        }

        copie.setId(source.getId());
        copie.setClient(source.getClient());
        copie.setIdHotel(source.getIdHotel());
        copie.setHotel(source.getHotel());
        copie.setDateHeureDepart(source.getDateHeureDepart());
        copie.setNbPassager(Math.max(0, nbPassagers));
        return copie;
    }

    public static class DivisionReservationResult {
        private List<ReservationEnrichi> reservationsAssignees;
        private int passagersRestants;

        public DivisionReservationResult() {
            this.reservationsAssignees = new ArrayList<>();
            this.passagersRestants = 0;
        }

        public List<ReservationEnrichi> getReservationsAssignees() {
            return reservationsAssignees;
        }

        public int getPassagersRestants() {
            return passagersRestants;
        }

        public void setPassagersRestants(int passagersRestants) {
            this.passagersRestants = Math.max(0, passagersRestants);
        }
    }

    public List<EtapeItineraire> calculerItineraireDetaille(VehiclePlanningDTO planning, PlanningConfig config,
                                                              Lieu aeroport, List<Distance> distances, List<Lieu> lieux) {
        List<EtapeItineraire> itineraire = new ArrayList<>();
        
        if (planning.getClients().isEmpty()) return itineraire;
        
        List<ClientInfo> clientsTries = new ArrayList<>(planning.getClients());
        clientsTries.sort((c1, c2) -> {
            Lieu h1 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c1.getHotel().toLowerCase()) 
                          || c1.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            Lieu h2 = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(c2.getHotel().toLowerCase()) 
                          || c2.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst().orElse(null);
            
            if (h1 == null || h2 == null) return 0;
            double dist1 = Distance.getDistanceBetween(aeroport.getId(), h1.getId(), distances);
            double dist2 = Distance.getDistanceBetween(aeroport.getId(), h2.getId(), distances);
            return Double.compare(dist1, dist2);
        });
        
        String heureDepart = planning.getDateHeureDepart();
        java.time.LocalDateTime heureActuelle = null;
        
        try {
            String[] parts = heureDepart.split(":");
            heureActuelle = java.time.LocalDate.now()
                .atTime(Integer.parseInt(parts[0]), Integer.parseInt(parts[1]));
        } catch (Exception e) {
            return itineraire;
        }
        
        Lieu lieuActuel = aeroport;
        
        for (int i = 0; i < clientsTries.size(); i++) {
            ClientInfo client = clientsTries.get(i);
            
            Lieu lieuHotel = lieux.stream()
                .filter(l -> l.getLibelle().toLowerCase().contains(client.getHotel().toLowerCase()) 
                          || client.getHotel().toLowerCase().contains(l.getLibelle().toLowerCase()))
                .findFirst()
                .orElse(null);
            
            if (lieuHotel != null) {
                double distance = Distance.getDistanceBetween(lieuActuel.getId(), lieuHotel.getId(), distances);
                
                double tempsTrajetHeures = distance / config.getVitesseMoyenne();
                long heures = (long) tempsTrajetHeures;
                long minutes = (long) ((tempsTrajetHeures - heures) * 60);
                
                heureActuelle = heureActuelle.plusHours(heures).plusMinutes(minutes);
                
                java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
                String heureArrivee = formatter.format(heureActuelle);
                
                EtapeItineraire etape = new EtapeItineraire();
                etape.setOrdre(i + 1);
                etape.setLieuDepart(lieuActuel.getLibelle());
                etape.setLieuArrivee(lieuHotel.getLibelle());
                etape.setDistance(distance);
                etape.setHeureArrivee(heureArrivee);
                etape.setNomClient(client.getNomClient());
                etape.setNbPassager(client.getNbPassager());
                
                itineraire.add(etape);
                
                if (config.getTempsAttente() > 0) {
                    heureActuelle = heureActuelle.plusMinutes(config.getTempsAttente());
                }
                
                lieuActuel = lieuHotel;
            }
        }
        
        double distanceRetour = Distance.getDistanceBetween(lieuActuel.getId(), aeroport.getId(), distances);
        double tempsRetourHeures = distanceRetour / config.getVitesseMoyenne();
        long heuresRetour = (long) tempsRetourHeures;
        long minutesRetour = (long) ((tempsRetourHeures - heuresRetour) * 60);
        
        heureActuelle = heureActuelle.plusHours(heuresRetour).plusMinutes(minutesRetour);
        
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
        String heureArriveeAeroport = formatter.format(heureActuelle);
        
        EtapeItineraire etapeRetour = new EtapeItineraire();
        etapeRetour.setOrdre(clientsTries.size() + 1);
        etapeRetour.setLieuDepart(lieuActuel.getLibelle());
        etapeRetour.setLieuArrivee(aeroport.getLibelle());
        etapeRetour.setDistance(distanceRetour);
        etapeRetour.setHeureArrivee(heureArriveeAeroport);
        etapeRetour.setNomClient("Retour aeroport");
        etapeRetour.setNbPassager(0);
        
        itineraire.add(etapeRetour);
        
        return itineraire;
    }

    public List<Vehicule> getAllVehicules() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            return Planning.getAllVehicules(conn);
        }
    }

    public static class EtapeItineraire {
        private int ordre;
        private String lieuDepart;
        private String lieuArrivee;
        private double distance;
        private String heureArrivee;
        private String nomClient;
        private int nbPassager;
        
        public int getOrdre() { return ordre; }
        public void setOrdre(int ordre) { this.ordre = ordre; }
        
        public String getLieuDepart() { return lieuDepart; }
        public void setLieuDepart(String lieuDepart) { this.lieuDepart = lieuDepart; }
        
        public String getLieuArrivee() { return lieuArrivee; }
        public void setLieuArrivee(String lieuArrivee) { this.lieuArrivee = lieuArrivee; }
        
        public double getDistance() { return distance; }
        public void setDistance(double distance) { this.distance = distance; }
        
        public String getHeureArrivee() { return heureArrivee; }
        public void setHeureArrivee(String heureArrivee) { this.heureArrivee = heureArrivee; }
        
        public String getNomClient() { return nomClient; }
        public void setNomClient(String nomClient) { this.nomClient = nomClient; }
        
        public int getNbPassager() { return nbPassager; }
        public void setNbPassager(int nbPassager) { this.nbPassager = nbPassager; }
    }
}
