package dao;

import java.sql.SQLException;
import models.Passeport;

public interface PasseportDao {
    Passeport findByNum(String numeroPasseport) throws SQLException;
}
