package kz.testcenter.updates.db.exceptions;

/**
 * Created by user on 30.03.2015.
 */
public class DAONotFoundException extends DAOException {
    public DAONotFoundException(String message) {
        super(message);
    }

    public DAONotFoundException(String message, int code) {
        super(message, code);
    }

    private static final long serialVersionUID = 5707192613462411819L;
}