package kz.testcenter.updates.db.exceptions;

import javax.ejb.ApplicationException;

/**
 * Created by user on 30.03.2015.
 */
@ApplicationException(rollback = true)
public class DAOException extends Exception {
    public DAOException(String message) {
        super(message);
        this.exceptionMessage = new ExceptionMessage(message);
    }

    public DAOException(String message, int code) {
        super(message);
        this.exceptionMessage = new ExceptionMessage(message, code);
    }

    private static final long serialVersionUID = 5661098247691021399L;

    public ExceptionMessage getExceptionMessage() {
        return this.exceptionMessage;
    }
    public void setExceptionMessage(ExceptionMessage exceptionMessage) {
        this.exceptionMessage = exceptionMessage;
    }
    private ExceptionMessage exceptionMessage;
}