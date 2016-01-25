package kz.testcenter.updates.db.exceptions;

/**
 * Created by user on 30.03.2015.
 */
public class DAOForbiddenException extends DAOException {
    public DAOForbiddenException(String message) {
        super(message);
    }

    public DAOForbiddenException(String message, int code) {
        super(message, code);
    }

    private static final long serialVersionUID = -3196335792012601194L;
}