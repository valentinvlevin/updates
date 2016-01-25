package kz.testcenter.updates.db.dao;

import kz.testcenter.updates.common.MyJsonBuilder;
import kz.testcenter.updates.db.entities.users.User;
import kz.testcenter.updates.db.entities.users.UserType;
import kz.testcenter.updates.db.exceptions.*;

import javax.annotation.PostConstruct;
import javax.annotation.security.PermitAll;
import javax.annotation.security.RolesAllowed;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.NoResultException;
import javax.persistence.Query;
import java.util.HashMap;
import java.util.List;

@Singleton
@Startup
public class UserDAO {
    private final int MSG_COMMON_ERROR_CODE = 2000;
    private final int MSG_USER_WITH_SAME_USERNAME_ALREADY_EXISTS_ERROR_CODE = MSG_COMMON_ERROR_CODE+1;
    private final int MSG_USER_WITH_SAME_USERDISPLAYNAME_ALREADY_EXISTS_ERROR_CODE = MSG_COMMON_ERROR_CODE+2;

    private final int MSG_ILLEGAL_ARGUMENT_USERNAME_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+3;
    private final int MSG_ILLEGAL_ARGUMENT_USERDISPLAYNAME_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+4;
    private final int MSG_ILLEGAL_ARGUMENT_PASSWORD_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+5;

    private final int MSG_FORBIDDEN_ERROR_CODE = MSG_COMMON_ERROR_CODE+6;
    private final int MSG_UNABLE_DELETE_ADMINISTRATOR_ERROR_CODE = MSG_COMMON_ERROR_CODE+7;

    private final int MSG_USER_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+8;

    private final String QRY_GET_USER_LIST_JSON = "UserDAO.getListOfUsersJson";
    private final String[] QRY_GET_USER_LIST_JSON_FIELD_NAMES = {"id", "username", "display_username"};

    private final String QRY_GET_USER_BY_USERNAME = "UserDAO.getUserByUserName";
    private final String QRY_GET_USER_BY_ID = "UserDAO.getUserById";
    private final String[] QRY_GET_USER_JSON_FIELD_NAMES = {"id", "group", "display_username"};

    private final String QRY_GET_COUNT_USER_BY_USERNAME = "UserDAO.getUserCountByUserName";
    private final String QRY_GET_COUNT_USER_BY_USERDISPLAYNAME = "UserDAO.getUserCountByUserDisplayName";

    private final String QRY_GET_USER_LIST = "UserDAO.getUserList";

    @Inject
    private EntityManager em;

    private HashMap<String, User> userList = new HashMap<>();

    @PostConstruct
    public void init() {
        EntityManagerFactory emf = em.getEntityManagerFactory();
        Query q;

        q = em.createQuery("select o.id, o.userName, o.userDislayName from User o");
        emf.addNamedQuery(QRY_GET_USER_LIST_JSON, q);

        q = em.createQuery("select o from User o where o.userName = :userName", User.class);
        emf.addNamedQuery(QRY_GET_USER_BY_USERNAME, q);

        q = em.createQuery("select o.id, o.roleName, o.userDislayName from User o where o.id = :id");
        emf.addNamedQuery(QRY_GET_USER_BY_ID, q);

        q = em.createQuery("select o from User o", User.class);
        emf.addNamedQuery(QRY_GET_USER_LIST, q);

        q = em.createQuery("select count(o) from User o where o.userName = :userName and o.id<>:userId", Long.class);
        emf.addNamedQuery(QRY_GET_COUNT_USER_BY_USERNAME, q);

        q = em.createQuery("select count(o) from User o where o.userDislayName = :userDisplayName and o.id<>:userId", Long.class);
        emf.addNamedQuery(QRY_GET_COUNT_USER_BY_USERDISPLAYNAME, q);

        loadUserList();
    }

    @PermitAll
    public User getUserByUserName(String userName) {
        if (!userList.containsKey(userName)) {
            User user = em.createNamedQuery(QRY_GET_USER_BY_USERNAME, User.class)
                        .setParameter("userName", userName)
                        .getSingleResult();
            if (user != null) {
                em.detach(user);
                userList.put(user.getUserName(), user);
            }

            return user;
        } else
            return userList.get(userName);
    }

    @PermitAll
    public String getUserById(int id) throws DAOException{
        try {
            Object[] data = em.createNamedQuery(QRY_GET_USER_BY_ID, Object[].class)
                    .setParameter("id", id)
                    .getSingleResult();
            return MyJsonBuilder.buildJsonObject(QRY_GET_USER_JSON_FIELD_NAMES, data);
        } catch (NoResultException e) {
            throw new DAONotFoundException("User with Id "+id+" not found", MSG_USER_NOT_FOUND_ERROR_CODE);
        }
    }

    public void loadUserList() {
        userList.clear();
        for (User user : em.createNamedQuery(QRY_GET_USER_LIST, User.class).getResultList()){
            userList.put(user.getUserName(), user);
            em.detach(user);
        }
    }

    private boolean isUserWithUserNameExists(String userName, int userId) {
        return em.createNamedQuery(QRY_GET_COUNT_USER_BY_USERNAME, Long.class)
                .setParameter("userName", userName)
                .setParameter("userId", userId)
                    .getSingleResult()>0;
    }

    private boolean isUserWithUserDisplayNameExists(String userDisplayName, int userId) {
        return em.createNamedQuery(QRY_GET_COUNT_USER_BY_USERDISPLAYNAME, Long.class)
                .setParameter("userDisplayName", userDisplayName)
                .setParameter("userId", userId)
                .getSingleResult()>0;
    }

    @PermitAll
    public String getUserListJson() throws DAOException {
        try {
            List<Object[]> data = em.createNamedQuery(QRY_GET_USER_LIST_JSON, Object[].class).getResultList();
            return MyJsonBuilder.buildJsonArray(QRY_GET_USER_LIST_JSON_FIELD_NAMES, data);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    @RolesAllowed("admin")
    public int addUser(String userName, String userDisplayName, String password) throws DAOException {
        if (userName == null || userName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано имя пользователя (user_name)",
                    MSG_ILLEGAL_ARGUMENT_USERNAME_EMPTY_ERROR_CODE);

        if (userDisplayName == null || userDisplayName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано имя пользователя для отображения (user_display_name)",
                    MSG_ILLEGAL_ARGUMENT_USERDISPLAYNAME_EMPTY_ERROR_CODE);

        if (password == null || password.isEmpty())
            throw new DAOIllegalArgumentException("Не задан пароль (password)",
                    MSG_ILLEGAL_ARGUMENT_PASSWORD_EMPTY_ERROR_CODE);

        if (isUserWithUserNameExists(userName, 0))
            throw new DAOAlreadyExistsException("Пользователь с такми именем пользователя (user_name) уже существует",
                MSG_USER_WITH_SAME_USERNAME_ALREADY_EXISTS_ERROR_CODE);

        if (isUserWithUserDisplayNameExists(userDisplayName, 0))
            throw new DAOAlreadyExistsException("Пользователь с такми именем пользователя для отображения (user_display_name) уже существует",
                    MSG_USER_WITH_SAME_USERDISPLAYNAME_ALREADY_EXISTS_ERROR_CODE);

        try {
            User newUser = new User();
            newUser.setUserName(userName);
            newUser.setUserDislayName(userDisplayName);
            newUser.setNewPassWord(password);

            em.persist(newUser);

            em.detach(newUser);
            userList.put(userName, newUser);

            return newUser.getId();
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    @RolesAllowed({"admin", "user"})
    public void changeUserData(int userId, String userName, String userDisplayName, String password, User caller)
        throws DAOException
    {
        if (caller.getUserType() == UserType.USER && caller.getId()!=userId)
            throw new DAOForbiddenException("Нельзя менять чужие данные", MSG_FORBIDDEN_ERROR_CODE);

        if (userName == null || userName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано имя пользователя (user_name)",
                    MSG_ILLEGAL_ARGUMENT_USERNAME_EMPTY_ERROR_CODE);

        if (userDisplayName == null || userDisplayName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано имя пользователя для отображения (user_display_name)",
                    MSG_ILLEGAL_ARGUMENT_USERDISPLAYNAME_EMPTY_ERROR_CODE);

        if (password == null || password.isEmpty())
            throw new DAOIllegalArgumentException("Не задан пароль (password)",
                    MSG_ILLEGAL_ARGUMENT_PASSWORD_EMPTY_ERROR_CODE);

        User user = em.find(User.class, userId);
        if (user == null)
            throw new DAONotFoundException("Не найден пользователь с ID \""+String.valueOf(userId)+"\"",
                    MSG_USER_NOT_FOUND_ERROR_CODE);

        if (!user.getUserName().equals(userName) && userList.containsKey(user.getUserName()))
            userList.remove(user.getUserName());

        if (isUserWithUserNameExists(userName, userId))
            throw new DAOAlreadyExistsException("Пользователь с таким именем пользователя (user_name) уже существует",
                    MSG_USER_WITH_SAME_USERNAME_ALREADY_EXISTS_ERROR_CODE);

        if (isUserWithUserDisplayNameExists(userDisplayName, userId))
            throw new DAOAlreadyExistsException("Пользователь с таким именем пользователя для отображения (user_display_name) уже существует",
                    MSG_USER_WITH_SAME_USERDISPLAYNAME_ALREADY_EXISTS_ERROR_CODE);

        try {
            user.setUserName(userName);
            user.setUserDislayName(userDisplayName);
            user.setNewPassWord(password);

            em.merge(user);

            em.detach(user);
            userList.put(userName, user);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    @RolesAllowed({"admin"})
    public void removeUser(int userId) throws DAOException
    {
        try {
            User user = em.find(User.class, userId);
            if (user == null)
                throw new DAONotFoundException("Не найден пользователь с ID \""+String.valueOf(userId)+"\"",
                        MSG_USER_NOT_FOUND_ERROR_CODE);

            if (user.getUserType() == UserType.ADMIN)
                throw new DAOIllegalArgumentException("Пользователя 'Администратор' удалять нельзя",
                            MSG_UNABLE_DELETE_ADMINISTRATOR_ERROR_CODE);
            em.remove(user);

            if (userList.containsKey(user.getUserName()))
                userList.remove(user.getUserName());
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }
}
