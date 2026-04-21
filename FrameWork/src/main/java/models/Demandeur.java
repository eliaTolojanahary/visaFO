package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Demandeur {
    private long id;
    private String nom;
    private String prenom;
    private String nom_jeune_fille;
    private LocalDate date_naissance;
    private SituationFamille situation_famille;
    private Nationalite nationalite;
    private String adresse_madagascar;
    private String numero_telephone;
    private String email;
    private String profession;
    private Timestamp created_at;
    private Timestamp updated_at;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }

    public String getNom_jeune_fille() { return nom_jeune_fille; }
    public void setNom_jeune_fille(String nom_jeune_fille) { this.nom_jeune_fille = nom_jeune_fille; }

    public LocalDate getDate_naissance() { return date_naissance; }
    public void setDate_naissance(LocalDate date_naissance) { this.date_naissance = date_naissance; }

    public SituationFamille getSituation_famille() { return situation_famille; }
    public void setSituation_famille(SituationFamille situation_famille) { this.situation_famille = situation_famille; }

    public Nationalite getNationalite() { return nationalite; }
    public void setNationalite(Nationalite nationalite) { this.nationalite = nationalite; }

    public String getAdresse_madagascar() { return adresse_madagascar; }
    public void setAdresse_madagascar(String adresse_madagascar) { this.adresse_madagascar = adresse_madagascar; }

    public String getNumero_telephone() { return numero_telephone; }
    public void setNumero_telephone(String numero_telephone) { this.numero_telephone = numero_telephone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getProfession() { return profession; }
    public void setProfession(String profession) { this.profession = profession; }

    public Timestamp getCreated_at() { return created_at; }
    public void setCreated_at(Timestamp created_at) { this.created_at = created_at; }

    public Timestamp getUpdated_at() { return updated_at; }
    public void setUpdated_at(Timestamp updated_at) { this.updated_at = updated_at; }
}