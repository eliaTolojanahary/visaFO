package models;

import java.sql.Timestamp;

public class Dossier {
    private long id;
    private String previous_demande_ref;
    private String new_demande_ref;
    private String mention;
    private boolean visa_approuve_confirme;
    private Timestamp created_at;
    private Timestamp updated_at;

    public long getId() { return id; }
    public void setId(long id) { this.id = id; }

    public String getPrevious_demande_ref() { return previous_demande_ref; }
    public void setPrevious_demande_ref(String previous_demande_ref) { this.previous_demande_ref = previous_demande_ref; }

    public String getNew_demande_ref() { return new_demande_ref; }
    public void setNew_demande_ref(String new_demande_ref) { this.new_demande_ref = new_demande_ref; }

    public String getMention() { return mention; }
    public void setMention(String mention) { this.mention = mention; }

    public boolean isVisa_approuve_confirme() { return visa_approuve_confirme; }
    public void setVisa_approuve_confirme(boolean visa_approuve_confirme) { this.visa_approuve_confirme = visa_approuve_confirme; }

    public Timestamp getCreated_at() { return created_at; }
    public void setCreated_at(Timestamp created_at) { this.created_at = created_at; }

    public Timestamp getUpdated_at() { return updated_at; }
    public void setUpdated_at(Timestamp updated_at) { this.updated_at = updated_at; }
}