package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Demande {
 
    // attributs
    private long id;
    private Passeport passeport ; // => initialiser avec id passeport 
    private TypeDemande type_demande; // => initialiser avec id type demande
    private TypeTitre type_titre; // => initiliser avec id type titre
    private StatutDemande statut; // => initiliser avec id statut_demande 
    private LocalDate visa_date_entree;
    private String visa_lieu_entree;
    private LocalDate visa_date_expiration;
    private Timestamp created_at;
    private Timestamp updated_at;

    // setters
    public void setId(long Id)
    {
        id = Id;
    }
    public void setPasseport(Passeport Passeport)
    {
        passeport = Passeport;
    }
    public void setType_demande(TypeDemande Type_demande)
    {
        type_demande = Type_demande;
    }
    public void setType_titre(TypeTitre Type_titre)
    {
        type_titre = Type_titre;
    }
    public void setStatut(StatutDemande Statut)
    {
        statut = Statut;
    }
    public void setVisa_date_entree(LocalDate Visa_date_entree)
    {
        visa_date_entree = Visa_date_entree;
    }
    public void setVisa_lieu_entree(String Visa_lieu_entree)
    {
        visa_lieu_entree = Visa_lieu_entree;
    }
    public void setVisa_date_expiration(LocalDate Visa_date_expiration)
    {
        visa_date_expiration = Visa_date_expiration;
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
    public Passeport getPasseport()
    {
        return passeport;
    }
    public TypeDemande getType_demande()
    {
        return type_demande;
    }
    public TypeTitre getType_titre()
    {
        return type_titre;
    }
    public StatutDemande getStatut()
    {
        return statut;
    }
    public LocalDate getVisa_date_entree()
    {
        return visa_date_entree;
    }
    public String getVisa_lieu_entree()
    {
        return visa_lieu_entree;
    }
    public LocalDate getVisa_date_expiration()
    {
        return visa_date_expiration;
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
    public Demande(){
    }

    public Demande(Passeport Passeport, TypeDemande Type_demande, TypeTitre Type_titre, StatutDemande Statut)
    {
        this.passeport = Passeport;
        this.type_demande = Type_demande;
        this.type_titre = Type_titre;
        this.statut = Statut;
    }

    public Demande(Passeport Passeport, TypeDemande Type_demande, TypeTitre Type_titre,
                   StatutDemande Statut, LocalDate Visa_date_entree,
                   String Visa_lieu_entree, LocalDate Visa_date_expiration)
    {
        this.passeport = Passeport;
        this.type_demande = Type_demande;
        this.type_titre = Type_titre;
        this.statut = Statut;
        this.visa_date_entree = Visa_date_entree;
        this.visa_lieu_entree = Visa_lieu_entree;
        this.visa_date_expiration = Visa_date_expiration;
    }
}
