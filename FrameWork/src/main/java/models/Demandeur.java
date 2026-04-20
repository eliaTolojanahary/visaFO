package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Demandeur {
    
    private long id;
    private String nom;
    private String prenom;
    private String nom_jeune_fille;
    private LocalDate date_naissance;
    private SituationFamille situation_famille; // initialser avec id situation_famille
    private Nationalite nationalite; // initialiser avec id nationalite
    private String adresse_madagascar;
    private String numero_telephone;
    private String email;
    private String profession;
    private Timestamp created_at;
    private Timestamp updated_at;


    // setters
    public void setId(long Id)
    {
        id = Id;
    }
    public void setNom(String Nom)
    {
        nom = Nom;
    }
    public void setPrenom(String Prenom)
    {
        prenom = Prenom;
    }
    public void setNom_jeune_fille(String Nom_jeune_fille)
    {
        nom_jeune_fille = Nom_jeune_fille;
    }
    public void setDate_naissance(LocalDate Date_naissance)
    {
        date_naissance = Date_naissance;
    }
    public void setSituation_famille(SituationFamille Situation_famille)
    {
        situation_famille = Situation_famille;
    }
    public void setNationalite(Nationalite Nationalite)
    {
        nationalite = Nationalite;
    }
    public void setAdresse_madagascar(String Adresse_madagascar)
    {
        adresse_madagascar = Adresse_madagascar;
    }
    public void setNumero_telephone(String Numero_telephone)
    {
        numero_telephone = Numero_telephone;
    }
    public void setEmail(String Email)
    {
        email = Email;
    }
    public void setProfession(String Profession)
    {
        profession = Profession;
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
    public String getNom()
    {
        return nom;
    }
    public String getPrenom()
    {
        return prenom;
    }
    public String getNom_jeune_fille()
    {
        return nom_jeune_fille;
    }
    public LocalDate getDate_naissance()
    {
        return date_naissance;
    }
    public SituationFamille getSituation_famille()
    {
        return situation_famille;
    }
    public Nationalite getNationalite()
    {
        return nationalite;
    }
    public String getAdresse_madagascar()
    {
        return adresse_madagascar;
    }
    public String getNumero_telephone()
    {
        return numero_telephone;
    }
    public String getEmail()
    {
        return email;
    }
    public String getProfession()
    {
        return profession;
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
    public Demandeur(){
    }

    public Demandeur(String Nom, String Prenom, LocalDate Date_naissance)
    {
        this.nom = Nom;
        this.prenom = Prenom;
        this.date_naissance = Date_naissance;
    }

    public Demandeur(String Nom, String Prenom, String Nom_jeune_fille, LocalDate Date_naissance,
                     SituationFamille Situation_famille, Nationalite Nationalite, 
                     String Adresse_madagascar, String Numero_telephone, String Email, String Profession)
    {
        this.nom = Nom;
        this.prenom = Prenom;
        this.nom_jeune_fille = Nom_jeune_fille;
        this.date_naissance = Date_naissance;
        this.situation_famille = Situation_famille;
        this.nationalite = Nationalite;
        this.adresse_madagascar = Adresse_madagascar;
        this.numero_telephone = Numero_telephone;
        this.email = Email;
        this.profession = Profession;
    }
}
