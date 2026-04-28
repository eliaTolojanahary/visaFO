package dao;

import java.sql.SQLException;
import models.Dossier;

public interface DossierDao {
    Dossier create(Dossier dossier) throws SQLException;
    Dossier findByDemande(long demande_id) throws SQLException;
    Dossier findByDemandeurId(long demandeur_id) throws SQLException;
}