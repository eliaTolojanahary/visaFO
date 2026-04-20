package models;

public class TypeDemande {
    
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
    public TypeDemande(){
    }

    public TypeDemande(String Libelle)
    {
        this.libelle = Libelle;
    }

    public TypeDemande(long Id, String Libelle)
    {
        this.id = Id;
        this.libelle = Libelle;
    }
}
