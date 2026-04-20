package models;

public class StatutDemande {
    
    private long id;
    private String libelle; 

    // setters
    public void setId(long Id)
    {
        id = Id; 
    }
    public void setLibelle(String Libelle)
    {
        libelle = Libelle; 
    }

    // getters 
    public long getId()
    {
        return  id; 
    }
    public String getLibelle()
    {
        return  libelle; 
    }

    // Constructeurs
    public StatutDemande(){
    }

    public StatutDemande(String Libelle)
    {
        this.libelle = Libelle;
    }

    public StatutDemande(long Id, String Libelle)
    {
        this.id = Id;
        this.libelle = Libelle;
    }
}
