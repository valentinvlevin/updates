package kz.testcenter.updates.common;

import kz.testcenter.updates.db.dao.UserDAO;
import kz.testcenter.updates.db.entities.users.*;

import org.jboss.resteasy.spi.HttpRequest;

import javax.annotation.Resource;
import javax.ejb.SessionContext;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.inject.Inject;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.SecurityContext;

@Singleton
@Startup
public class UserProvider {
    @Inject
    private UserDAO userDAO;

    @Resource
    SessionContext context;

    public UserProvider(){}

    private UserType getUserType() {
        if (context.isCallerInRole("admin"))
            return UserType.ADMIN;
        else if (context.isCallerInRole("user"))
            return UserType.USER;
        else return UserType.NONE;
    }

    public User getUserByUserName(String userName) {
        UserType userType = getUserType();

        switch (userType) {
            case ADMIN:
            case USER:
                return userDAO.getUserByUserName(userName);
            default:
                return null;
        }
    }

    public User getCurrentUser() {
        String userName = context.getCallerPrincipal().getName();
        User user = getUserByUserName(userName);

        return user;
    }

}
