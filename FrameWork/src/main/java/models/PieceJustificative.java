package models;

public class PieceJustificative {
    private long id;
    private String libelle; 
    private TypeTitre type_titre;     

    // setters
    public void setId(long Id)
    {
        id = Id; 
    }
    public void setLibelle(String Libelle)
    {
        libelle = Libelle; 
    }
    public void setType_titre(TypeTitre Type_titre)
    {
        type_titre = Type_titre;
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
    public TypeTitre getType_titre(){
        return type_titre;
    }

    // Constructeurs
    public PieceJustificative(){
    }

    public PieceJustificative(String Libelle)
    {
        this.libelle = Libelle;
    }

    public PieceJustificative(long Id, String Libelle)
    {
        this.id = Id;
        this.libelle = Libelle;
    }

    public PieceJustificative(long Id, String Libelle, TypeTitre Type_titre)
    {
        this.id = Id;
        this.libelle = Libelle;
        this.type_titre = Type_titre;
    }


}
