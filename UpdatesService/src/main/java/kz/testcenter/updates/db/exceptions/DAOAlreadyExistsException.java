package kz.testcenter.updates.db.exceptions;

/**
 * Created by user on 30.03.2015.
 */
public class DAOAlreadyExistsException extends DAOException {
    public DAOAlreadyExistsException(String message) {
        super(message);
    }

    public DAOAlreadyExistsException(String message, int code) {
        super(message, code);
    }

    private static final long serialVersionUID = 3685990401903515820L;
}