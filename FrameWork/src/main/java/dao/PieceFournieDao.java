package dao;

import java.sql.SQLException;
import java.util.List;
import models.PieceFournie;

public interface PieceFournieDao {
    PieceFournie create(PieceFournie piece) throws SQLException;
    PieceFournie findByDemandeAndPieceRef(long demandeId, long pieceRefId) throws SQLException;
    List<PieceFournie> findAllByDemande(long demandeId) throws SQLException;
    void deleteByDemandeAndPieceRef(long demandeId, long pieceRefId) throws SQLException;
}
