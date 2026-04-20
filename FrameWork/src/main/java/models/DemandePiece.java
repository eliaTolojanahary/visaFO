package models;

import java.sql.Timestamp;

public class DemandePiece {
    private long id;
    private Demande demande;
    private PieceJustificative piece;
    private boolean cochee;
    private Timestamp created_at;

    public DemandePiece(){
    }

    public DemandePiece(Demande Demande, PieceJustificative Piece, boolean Cochee)
    {
        this.demande = Demande;
        this.piece = Piece;
        this.cochee = Cochee;
    }

    public void setId(long Id)
    {
        id = Id;
    }
    public void setDemande(Demande Demande)
    {
        demande = Demande;
    }
    public void setPiece(PieceJustificative Piece)
    {
        piece = Piece;
    }
    public void setCochee(boolean Cochee)
    {
        cochee = Cochee;
    }
    public void setCreated_at(Timestamp Created_at)
    {
        created_at = Created_at;
    }

    public long getId()
    {
        return id;
    }
    public Demande getDemande()
    {
        return demande;
    }
    public PieceJustificative getPiece()
    {
        return piece;
    }
    public boolean isCochee()
    {
        return cochee;
    }
    public Timestamp getCreated_at()
    {
        return created_at;
    }
}
