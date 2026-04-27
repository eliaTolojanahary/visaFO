package dao;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import models.Demande;

public interface DemandeDao {
    long save(Demande demande) throws SQLException;
    boolean update(Demande demande) throws SQLException;
    Demande findById(long id) throws SQLException;
    Demande findBy(String column, Object value) throws SQLException;
    void saveDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException;
    void replaceDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException;
    Long findLatestDemandeIdByNumeroPasseport(String numeroPasseport) throws SQLException;
    Map<String, Object> getFormDataByDemandeId(long demandeId) throws SQLException;
    List<Long> getSelectedPieceIdsByDemandeId(long demandeId) throws SQLException;
    Map<String, Object> searchDemandeurEtPasseport(String nom, String prenom, String dateNaissance, String numeroPasseport) throws SQLException;
    Map<String, Object> getLatestDemandeDashboardData() throws SQLException;
    List<Map<String, Object>> getDashboardDemandesData() throws SQLException;
    Long findPasseportIdByNumero(String numeroPasseport) throws SQLException;
    long insertDemandeur(Map<String, Object> formData) throws SQLException;
    long insertPasseport(long demandeurId, Map<String, Object> formData) throws SQLException;
}
