package repo;

import dao.ReferenceVisaDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.Nationalite;
import models.StatutDemande;
import models.SituationFamille;
import models.TypeDemande;
import models.TypeTitre;
import util.DatabaseConnection;

public class ReferenceVisaRepository implements ReferenceVisaDao {

    @Override
    public StatutDemande findStatutByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id, libelle FROM  statut_demande WHERE LOWER(libelle) = LOWER(?) LIMIT 1";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, libelle);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    StatutDemande statut = new StatutDemande();
                    statut.setId(rs.getLong("id"));
                    statut.setLibelle(rs.getString("libelle"));
                    return statut;
                }
            }
        }

        return null;
    }

    @Override
    public TypeTitre findTypeTitreById(Long id) throws SQLException {
        if (id == null) {
            return null;
        }

        String sql = "SELECT id, libelle FROM  type_titre WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    TypeTitre typeTitre = new TypeTitre();
                    typeTitre.setId(rs.getLong("id"));
                    typeTitre.setLibelle(rs.getString("libelle"));
                    return typeTitre;
                }
            }
        }

        return null;
    }

    @Override
    public TypeDemande findTypeDemandeById(long id) throws SQLException {
        String sql = "SELECT id, libelle FROM  type_demande WHERE id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    TypeDemande typeDemande = new TypeDemande();
                    typeDemande.setId(rs.getLong("id"));
                    typeDemande.setLibelle(rs.getString("libelle"));
                    return typeDemande;
                }
            }
        }

        return null;
    }

    @Override
    public List<TypeTitre> findAllTypeTitres() throws SQLException {
        String sql = "SELECT id, libelle FROM  type_titre ORDER BY id";
        List<TypeTitre> types = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                TypeTitre typeTitre = new TypeTitre();
                typeTitre.setId(rs.getLong("id"));
                typeTitre.setLibelle(rs.getString("libelle"));
                types.add(typeTitre);
            }
        }

        return types;
    }

    @Override
    public List<SituationFamille> findAllSituationsFamille() throws SQLException {
        System.out.println("[DEBUG REPO] findAllSituationsFamille() appelé");
        String sql = "SELECT id, libelle FROM  situation_famille ORDER BY id";
        List<SituationFamille> situations = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            System.out.println("[DEBUG REPO] SQL exécuté: " + sql);
            while (rs.next()) {
                SituationFamille situation = new SituationFamille();
                situation.setId(rs.getLong("id"));
                situation.setLibelle(rs.getString("libelle"));
                situations.add(situation);
            }
            System.out.println("[DEBUG REPO] Situations familiales chargées: " + situations.size());
        } catch (SQLException e) {
            System.err.println("[DEBUG REPO] ERREUR SQL: " + e.getMessage());
            throw e;
        }

        return situations;
    }

    @Override
    public List<Nationalite> findAllNationalites() throws SQLException {
        System.out.println("[DEBUG REPO] findAllNationalites() appelé");
        String sql = "SELECT id, libelle FROM  nationalite ORDER BY id";
        List<Nationalite> nationalites = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            System.out.println("[DEBUG REPO] SQL exécuté: " + sql);
            while (rs.next()) {
                Nationalite nationalite = new Nationalite();
                nationalite.setId(rs.getLong("id"));
                nationalite.setLibelle(rs.getString("libelle"));
                nationalites.add(nationalite);
            }
            System.out.println("[DEBUG REPO] Nationalités chargées: " + nationalites.size());
        } catch (SQLException e) {
            System.err.println("[DEBUG REPO] ERREUR SQL: " + e.getMessage());
            throw e;
        }

        return nationalites;
    }

    @Override
    public List<TypeDemande> findAllTypesDemande() throws SQLException {
        System.out.println("[DEBUG REPO] findAllTypesDemande() appelé");
        String sql = "SELECT id, libelle FROM  type_demande ORDER BY id";
        List<TypeDemande> types = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            System.out.println("[DEBUG REPO] SQL exécuté: " + sql);
            while (rs.next()) {
                TypeDemande typeDemande = new TypeDemande();
                typeDemande.setId(rs.getLong("id"));
                typeDemande.setLibelle(rs.getString("libelle"));
                types.add(typeDemande);
            }
            System.out.println("[DEBUG REPO] Types de demande chargés: " + types.size());
        } catch (SQLException e) {
            System.err.println("[DEBUG REPO] ERREUR SQL: " + e.getMessage());
            throw e;
        }

        return types;
    }
}
