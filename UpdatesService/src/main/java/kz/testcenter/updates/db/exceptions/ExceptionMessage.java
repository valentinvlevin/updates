package kz.testcenter.updates.db.exceptions;

import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "ErrorMessage")
public class ExceptionMessage {

    @XmlElement(name = "message")
    public String getErrorMessage() {
        return this.errorMessage;
    }
    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }
    private String errorMessage;


    @XmlAttribute(name = "code")
    public int getCode() {
        return this.code;
    }
    public void setCode(int code) {
        this.code = code;
    }
    private int code;

    ExceptionMessage(String message, int code) {
        this.errorMessage = message;
        this.code = code;
    }

    ExceptionMessage(String message) {
        this.errorMessage = message;
        this.code = 0;
    }
}
