package kz.testcenter.updates.db.exceptions;

/**
 * Created by user on 30.03.2015.
 */
public class DAOIllegalArgumentException extends DAOException {
    public DAOIllegalArgumentException(String message) {
        super(message);
    }

    public DAOIllegalArgumentException(String message, int code) {
        super(message, code);
    }

    private static final long serialVersionUID = -5624282266586383811L;
}