package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import models.DossierDemande;

public interface DossierDemandeDao {
    
    DossierDemande findDossierDemande(Long dossierId, Long demandeId) throws SQLException ;
    void updateDossierDemandeScanTermine(long dossierDemandeId) throws SQLException;
}
