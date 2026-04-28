package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Demande {
    private long id;
    private Passeport passeport;
    private TypeDemande type_demande;
    private TypeTitre type_titre;
    private StatutDemande statut;
    private LocalDate visa_date_entree;
    private String visa_lieu_entree;
    private LocalDate visa_date_expiration;
    private String ref_demande;
    private boolean verrouille;
    private TypeDocument type_document;
    private Timestamp created_at;
    private Timestamp updated_at;
    private boolean verrouille;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public Passeport getPasseport() { return passeport; }
    public void setPasseport(Passeport passeport) { this.passeport = passeport; }

    public TypeDemande getType_demande() { return type_demande; }
    public void setType_demande(TypeDemande type_demande) { this.type_demande = type_demande; }

    public TypeTitre getType_titre() { return type_titre; }
    public void setType_titre(TypeTitre type_titre) { this.type_titre = type_titre; }

    public StatutDemande getStatut() { return statut; }
    public void setStatut(StatutDemande statut) { this.statut = statut; }

    public LocalDate getVisa_date_entree() { return visa_date_entree; }
    public void setVisa_date_entree(LocalDate visa_date_entree) { this.visa_date_entree = visa_date_entree; }

    public String getVisa_lieu_entree() { return visa_lieu_entree; }
    public void setVisa_lieu_entree(String visa_lieu_entree) { this.visa_lieu_entree = visa_lieu_entree; }

    public LocalDate getVisa_date_expiration() { return visa_date_expiration; }
    public void setVisa_date_expiration(LocalDate visa_date_expiration) { this.visa_date_expiration = visa_date_expiration; }

    public String getRef_demande() { return ref_demande; }
    public void setRef_demande(String ref_demande) { this.ref_demande = ref_demande; }

    public boolean isVerrouille() { return verrouille; }
    public void setVerrouille(boolean verrouille) { this.verrouille = verrouille; }

    public TypeDocument getType_document() { return type_document; }
    public void setType_document(TypeDocument type_document) { this.type_document = type_document; }

    public Timestamp getCreated_at() { return created_at; }
    public void setCreated_at(Timestamp created_at) { this.created_at = created_at; }

    public Timestamp getUpdated_at() { return updated_at; }
    public void setUpdated_at(Timestamp updated_at) { this.updated_at = updated_at; }

    public boolean isVerrouille() { return verrouille; }
    public void setVerrouille(boolean verrouille) { this.verrouille = verrouille; }
}
