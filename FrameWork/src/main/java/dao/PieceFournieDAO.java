package dao;

import java.util.List;
import models.PieceFournie;

/**
 * Prototype Sprint 3 (sans implementation).
 */
public interface PieceFournieDAO {
    PieceFournie create(PieceFournie p);
    PieceFournie findByDemandeAndPieceRef(long demandeId, long pieceRefId);
    List<PieceFournie> findAllByDemande(long demandeId);
    boolean deleteByDemandeAndPieceRef(long demandeId, long pieceRefId);
}
