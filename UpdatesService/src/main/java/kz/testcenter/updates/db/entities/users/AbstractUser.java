package kz.testcenter.updates.db.entities.users;

import java.security.MessageDigest;
import java.util.Base64;

public abstract class AbstractUser {
    private String userName;
    protected String getUserName(){
        return this.userName;
    }
    protected void setUserName(String userName) {
        this.userName = userName;
    }

    private UserType userType;
    public UserType getUserType() {
        return this.userType;
    }

    private String passWord;
    protected void setPassWord(String passWord){
        this.passWord = passWord;
    }
    protected String getPassWord(){
        return this.passWord;
    }

    public void setNewPassWord(String newPassWord) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] newPasswordBytes = newPassWord.getBytes();
        byte[] newPasswordHash = md.digest(newPasswordBytes);
        String newPasswordHash64 = Base64.getEncoder().encodeToString(newPasswordHash);

        this.passWord = newPasswordHash64;
    }

    public AbstractUser(){
        userType = UserType.NONE;
    }

    public AbstractUser(UserType userType) {
        this.userType = userType;
    }

    public AbstractUser(String userName, UserType userType) {
        this.userName = userName;
        this.userType = userType;
    }
}
