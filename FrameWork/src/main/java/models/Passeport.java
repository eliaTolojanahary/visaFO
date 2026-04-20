package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Passeport {
    
    private long id ;
    private Demandeur demandeur ; // => initialiser avec id demandeur 
    private String numero_passeport;
    private LocalDate date_delivrance;
    private LocalDate date_expiration;
    private String pays_delivrance; 
    private Timestamp created_at;
    private Timestamp updated_at;
    
    // setters
    public void setId(long Id)
    {
        id = Id;
    }
    public void setDemandeur(Demandeur Demandeur)
    {
        demandeur = Demandeur;
    }
    public void setNumero_passeport(String Numero_passeport)
    {
        numero_passeport = Numero_passeport;
    }
    public void setDate_delivrance(LocalDate Date_delivrance)
    {
        date_delivrance = Date_delivrance;
    }
    public void setDate_expiration(LocalDate Date_expiration)
    {
        date_expiration = Date_expiration;
    }
    public void setPays_delivrance(String Pays_delivrance)
    {
        pays_delivrance = Pays_delivrance;
    }
    public void setCreated_at(Timestamp Created_at)
    {
        created_at = Created_at;
    }
    public void setUpdated_at(Timestamp Updated_at)
    {
        updated_at = Updated_at;
    }

    // getters
    public long getId()
    {
        return id;
    }
    public Demandeur getDemandeur()
    {
        return demandeur;
    }
    public String getNumero_passeport()
    {
        return numero_passeport;
    }
    public LocalDate getDate_delivrance()
    {
        return date_delivrance;
    }
    public LocalDate getDate_expiration()
    {
        return date_expiration;
    }
    public String getPays_delivrance()
    {
        return pays_delivrance;
    }
    public Timestamp getCreated_at()
    {
        return created_at;
    }
    public Timestamp getUpdated_at()
    {
        return updated_at;
    }

    // Constructeurs
    public Passeport(){
    }

    public Passeport(Demandeur Demandeur, String Numero_passeport, LocalDate Date_delivrance, LocalDate Date_expiration, String Pays_delivrance)
    {
        this.demandeur = Demandeur;
        this.numero_passeport = Numero_passeport;
        this.date_delivrance = Date_delivrance;
        this.date_expiration = Date_expiration;
        this.pays_delivrance = Pays_delivrance;
    }
}
