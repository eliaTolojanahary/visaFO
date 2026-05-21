package models;

import java.sql.Timestamp;

public class DossierDemande {
    private long id;
    private long dossierId;
    private long demandeId;
    private boolean scanTermine;
    private Timestamp dateScanComplete;
    private Timestamp createdAt;

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getDossierId() {
        return dossierId;
    }

    public void setDossierId(long dossierId) {
        this.dossierId = dossierId;
    }

    public long getDemandeId() {
        return demandeId;
    }

    public void setDemandeId(long demandeId) {
        this.demandeId = demandeId;
    }

    public boolean isScanTermine() {
        return scanTermine;
    }

    public void setScanTermine(boolean scanTermine) {
        this.scanTermine = scanTermine;
    }

    public Timestamp getDateScanComplete() {
        return dateScanComplete;
    }

    public void setDateScanComplete(Timestamp dateScanComplete) {
        this.dateScanComplete = dateScanComplete;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}