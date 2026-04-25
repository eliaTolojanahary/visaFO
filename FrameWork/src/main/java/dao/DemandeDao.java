package dao;

import java.sql.SQLException;
import java.util.List;
import models.Demande;

public interface DemandeDao {
    long save(Demande demande) throws SQLException;
    boolean update(Demande demande) throws SQLException;
    Demande findById(long id) throws SQLException;
    Demande findBy(String column, Object value) throws SQLException;
    void saveDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException;
    void replaceDemandePieces(long demandeId, List<Long> pieceIds) throws SQLException;
}
