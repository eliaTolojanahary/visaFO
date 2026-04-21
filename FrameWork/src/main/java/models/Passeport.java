package models;

import java.sql.Timestamp;
import java.time.LocalDate;

public class Passeport {
    private long id;
    private Demandeur demandeur;
    private String numero_passeport;
    private LocalDate date_delivrance;
    private LocalDate date_expiration;
    private String pays_delivrance;
    private Timestamp created_at;
    private Timestamp updated_at;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public Demandeur getDemandeur() { return demandeur; }
    public void setDemandeur(Demandeur demandeur) { this.demandeur = demandeur; }

    public String getNumero_passeport() { return numero_passeport; }
    public void setNumero_passeport(String numero_passeport) { this.numero_passeport = numero_passeport; }

    public LocalDate getDate_delivrance() { return date_delivrance; }
    public void setDate_delivrance(LocalDate date_delivrance) { this.date_delivrance = date_delivrance; }

    public LocalDate getDate_expiration() { return date_expiration; }
    public void setDate_expiration(LocalDate date_expiration) { this.date_expiration = date_expiration; }

    public String getPays_delivrance() { return pays_delivrance; }
    public void setPays_delivrance(String pays_delivrance) { this.pays_delivrance = pays_delivrance; }

    public Timestamp getCreated_at() { return created_at; }
    public void setCreated_at(Timestamp created_at) { this.created_at = created_at; }

    public Timestamp getUpdated_at() { return updated_at; }
    public void setUpdated_at(Timestamp updated_at) { this.updated_at = updated_at; }
}