package dao;

import java.sql.SQLException;
import java.util.List;
import models.Nationalite;
import models.StatutDemande;
import models.SituationFamille;
import models.TypeDemande;
import models.TypeTitre;

public interface ReferenceVisaDao {
    StatutDemande findStatutByLibelle(String libelle) throws SQLException;
    TypeTitre findTypeTitreById(Long id) throws SQLException;
    TypeDemande findTypeDemandeById(long id) throws SQLException;
    List<TypeTitre> findAllTypeTitres() throws SQLException;
    List<SituationFamille> findAllSituationsFamille() throws SQLException;
    List<Nationalite> findAllNationalites() throws SQLException;
    List<TypeDemande> findAllTypesDemande() throws SQLException;
}
