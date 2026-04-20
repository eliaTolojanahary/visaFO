package repo;

import dao.ReferenceVisaDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import models.StatutDemande;
import models.TypeDemande;
import models.TypeTitre;
import util.DatabaseConnection;

public class ReferenceVisaRepository implements ReferenceVisaDao {

    @Override
    public StatutDemande findStatutByLibelle(String libelle) throws SQLException {
        String sql = "SELECT id, libelle FROM visa.statut_demande WHERE LOWER(libelle) = LOWER(?) LIMIT 1";

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

        String sql = "SELECT id, libelle FROM visa.type_titre WHERE id = ?";

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
        String sql = "SELECT id, libelle FROM visa.type_demande WHERE id = ?";

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
        String sql = "SELECT id, libelle FROM visa.type_titre ORDER BY id";
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
}
