package dao;

import java.sql.SQLException;
import java.util.List;
import models.PieceJustificative;

public interface PieceJustificativeDao {
    List<PieceJustificative> findAll() throws SQLException;
    List<PieceJustificative> findByTypeTitreId(Long typeTitreId) throws SQLException;
    PieceJustificative findById(long id) throws SQLException;
}
