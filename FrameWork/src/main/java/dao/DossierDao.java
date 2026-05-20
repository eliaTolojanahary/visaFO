package dao;

import java.sql.SQLException;
import models.Dossier;

public interface DossierDao {
    Dossier update(Dossier dossier) throws SQLException;
    Dossier create(Dossier dossier) throws SQLException;
    Dossier findById(long id) throws SQLException;
    Dossier findByDemande(long demande_id) throws SQLException;
    Dossier findByDemandeurId(long demandeur_id) throws SQLException;
    long findDossierIdByDemande(long demandeId) throws SQLException;
}