package dao;

import java.sql.SQLException;
import java.util.List;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeTitre;

public interface ReferenceVisaDao {
    StatutDemande findStatutByLibelle(String libelle) throws SQLException;
    TypeTitre findTypeTitreById(Long id) throws SQLException;
    TypeDemande findTypeDemandeById(long id) throws SQLException;
    List<TypeTitre> findAllTypeTitres() throws SQLException;
}
