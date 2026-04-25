package services;

import dao.PasseportDao;
import java.sql.SQLException;
import models.Passeport;
import repo.PasseportRepository;

public class PasseportService {

    private final PasseportDao passeportDao;

    public PasseportService() {
        this.passeportDao = new PasseportRepository();
    }

    public Passeport getByNum(String numeroPasseport) throws SQLException {
        return passeportDao.findByNum(numeroPasseport);
    }
}
