package models;

import java.time.LocalDate;

public class VisaDTO {
	private long demande_id;
	private String nom_demandeur;
	private String prenom_demandeur;
	private String numero_passeport;
	private String type_demande;
	private String type_titre;
	private String statut;
	private LocalDate visa_date_entree;
	private LocalDate visa_date_expiration;
	private String visa_lieu_entree;

	public VisaDTO(){
	}

	public long getDemande_id()
	{
		return demande_id;
	}
	public void setDemande_id(long Demande_id)
	{
		demande_id = Demande_id;
	}
	public String getNom_demandeur()
	{
		return nom_demandeur;
	}
	public void setNom_demandeur(String Nom_demandeur)
	{
		nom_demandeur = Nom_demandeur;
	}
	public String getPrenom_demandeur()
	{
		return prenom_demandeur;
	}
	public void setPrenom_demandeur(String Prenom_demandeur)
	{
		prenom_demandeur = Prenom_demandeur;
	}
	public String getNumero_passeport()
	{
		return numero_passeport;
	}
	public void setNumero_passeport(String Numero_passeport)
	{
		numero_passeport = Numero_passeport;
	}
	public String getType_demande()
	{
		return type_demande;
	}
	public void setType_demande(String Type_demande)
	{
		type_demande = Type_demande;
	}
	public String getType_titre()
	{
		return type_titre;
	}
	public void setType_titre(String Type_titre)
	{
		type_titre = Type_titre;
	}
	public String getStatut()
	{
		return statut;
	}
	public void setStatut(String Statut)
	{
		statut = Statut;
	}
	public LocalDate getVisa_date_entree()
	{
		return visa_date_entree;
	}
	public void setVisa_date_entree(LocalDate Visa_date_entree)
	{
		visa_date_entree = Visa_date_entree;
	}
	public LocalDate getVisa_date_expiration()
	{
		return visa_date_expiration;
	}
	public void setVisa_date_expiration(LocalDate Visa_date_expiration)
	{
		visa_date_expiration = Visa_date_expiration;
	}
	public String getVisa_lieu_entree()
	{
		return visa_lieu_entree;
	}
	public void setVisa_lieu_entree(String Visa_lieu_entree)
	{
		visa_lieu_entree = Visa_lieu_entree;
	}
}
