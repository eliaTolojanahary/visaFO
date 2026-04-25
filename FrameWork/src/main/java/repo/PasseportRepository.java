package repo;

import dao.PasseportDao;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import models.Demandeur;
import models.Nationalite;
import models.Passeport;
import models.SituationFamille;
import util.DatabaseConnection;

public class PasseportRepository implements PasseportDao {

    @Override
    public Passeport findByNum(String numeroPasseport) throws SQLException {
        String sql = "SELECT p.id, p.numero_passeport, p.date_delivrance, p.date_expiration, p.pays_delivrance, p.created_at, p.updated_at, "
                   + "d.id AS demandeur_id, d.nom, d.prenom, d.nom_jeune_fille, d.date_naissance, d.situation_famille_id, d.nationalite_id, "
                   + "d.adresse_madagascar, d.numero_telephone, d.email, d.profession, d.created_at AS demandeur_created_at, d.updated_at AS demandeur_updated_at "
                   + "FROM passeport p "
                   + "JOIN demandeur d ON p.demandeur_id = d.id "
                   + "WHERE p.numero_passeport = ? "
                   + "LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, numeroPasseport);
            try (ResultSet rs = stmt.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Passeport passeport = new Passeport();
                passeport.setId(rs.getLong("id"));
                passeport.setNumero_passeport(rs.getString("numero_passeport"));

                Date delivrance = rs.getDate("date_delivrance");
                if (delivrance != null) {
                    passeport.setDate_delivrance(delivrance.toLocalDate());
                }

                Date expiration = rs.getDate("date_expiration");
                if (expiration != null) {
                    passeport.setDate_expiration(expiration.toLocalDate());
                }

                passeport.setPays_delivrance(rs.getString("pays_delivrance"));
                passeport.setCreated_at(rs.getTimestamp("created_at"));
                passeport.setUpdated_at(rs.getTimestamp("updated_at"));

                Demandeur demandeur = new Demandeur();
                demandeur.setId(rs.getLong("demandeur_id"));
                demandeur.setNom(rs.getString("nom"));
                demandeur.setPrenom(rs.getString("prenom"));
                demandeur.setNom_jeune_fille(rs.getString("nom_jeune_fille"));

                Date naissance = rs.getDate("date_naissance");
                if (naissance != null) {
                    demandeur.setDate_naissance(naissance.toLocalDate());
                }

                SituationFamille situation = new SituationFamille();
                situation.setId(rs.getLong("situation_famille_id"));
                demandeur.setSituation_famille(situation);

                Nationalite nationalite = new Nationalite();
                nationalite.setId(rs.getLong("nationalite_id"));
                demandeur.setNationalite(nationalite);

                demandeur.setAdresse_madagascar(rs.getString("adresse_madagascar"));
                demandeur.setNumero_telephone(rs.getString("numero_telephone"));
                demandeur.setEmail(rs.getString("email"));
                demandeur.setProfession(rs.getString("profession"));
                demandeur.setCreated_at(rs.getTimestamp("demandeur_created_at"));
                demandeur.setUpdated_at(rs.getTimestamp("demandeur_updated_at"));

                passeport.setDemandeur(demandeur);
                return passeport;
            }
        }
    }
}
