package repo;

import dao.PieceFournieDAO;
import java.util.ArrayList;
import java.util.List;
import models.PieceFournie;

/**
 * Prototype Sprint 3 (sans implementation).
 */
public class PieceFournieRepository implements PieceFournieDAO {
    public PieceFournie create(PieceFournie p){
        return new PieceFournie();
    };
    public PieceFournie findByDemandeAndPieceRef(long demandeId, long pieceRefId){
        return new PieceFournie();
    };
    public List<PieceFournie> findAllByDemande(long demandeId){
        return new ArrayList<>();
    }
    public boolean deleteByDemandeAndPieceRef(long demandeId, long pieceRefId){
        return true;
    }
}
