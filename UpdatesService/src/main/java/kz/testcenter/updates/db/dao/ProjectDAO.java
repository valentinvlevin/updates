package kz.testcenter.updates.db.dao;

import kz.testcenter.updates.common.MyJsonBuilder;
import kz.testcenter.updates.db.entities.Project;
import kz.testcenter.updates.db.entities.users.User;
import kz.testcenter.updates.db.entities.users.UserType;
import kz.testcenter.updates.db.exceptions.*;

import javax.annotation.PostConstruct;
import javax.annotation.security.PermitAll;
import javax.annotation.security.RolesAllowed;
import javax.ejb.Startup;
import javax.inject.Inject;
import javax.inject.Singleton;
import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.NoResultException;
import javax.persistence.Query;
import java.util.List;

@Singleton
@Startup
public class ProjectDAO {
    private final int MSG_COMMON_ERROR_CODE = 1000;
    private final int MSG_PROJECT_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+1;

    private final int MSG_PROJECTNAME_IS_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+2;
    private final int MSG_DESC_IS_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+3;

    private final int MSG_PROJECT_WITH_SAME_PROJECTNAME_EXISTS_ERROR_CODE = MSG_COMMON_ERROR_CODE+4;
    private final int MSG_FORBIDDEN_CHANGE_PROJECT_ERROR_CODE = MSG_COMMON_ERROR_CODE+5;

    private final int MSG_PROJECT_HAVE_UPDATES_ERROR_CODE = MSG_COMMON_ERROR_CODE+6;

    private final int MSG_ID_PROJECT_IS_ZERO_ERROR_CODE = MSG_COMMON_ERROR_CODE+7;

    private final String QRY_GET_ALL_PROJECT_LIST_JSON = "ProjectDAO.getListOfAllProjectsJson";
    private final String QRY_GET_PROJECT_FOR_USER_LIST_JSON = "ProjectDAO.getListOfProjectsForUserJson";

    private final String QRY_GET_PROJECT_DETAILS_JSON = "ProjectDAO.getProjectDetailsJson";
    private final String QRY_GET_PROJECT_DETAILS_FOR_USER_JSON = "ProjectDAO.getProjectDetailsForUserJson";

    private final String[] QRY_GET_PROJECT_LIST_JSON_FIELD_NAMES = {"id", "projectName", "description", "canWrite"};

    private final String QRY_GET_PROJECT_COUNT_BY_PROJECTNAME = "ProjectDAO.getProjectCountByProjectName";
    private final String QRY_GET_UPDATE_COUNT_OF_PROJECT = "ProjectDAO.getUpdateCountOfProject";

    private final String QRY_GET_COUNT_WRITEABLE_PROJECTS_BY_USERID_AND_PROJECTID = "ProjectDAO.getCountWriteableProjectsByUserIdAndProjectId";

    @Inject
    private EntityManager em;

    @PostConstruct
    public void init() {
        EntityManagerFactory emf = em.getEntityManagerFactory();
        Query q;

        q = em.createQuery("select o.id, o.projectName, o.description, 1 AS canWrite from Project o");
        emf.addNamedQuery(QRY_GET_ALL_PROJECT_LIST_JSON, q);

        q = em.createQuery("select o.id, o.projectName, o.description, 1 AS canWrite from Project o where o.id=:projectId");
        emf.addNamedQuery(QRY_GET_PROJECT_DETAILS_JSON, q);

        q = em.createQuery(
                "select p.id, p.projectName, p.description, case when wr.id is not null then 1 else 0 end  as canWrite "+
                "from Project p left join p.writers wr on (wr.id=:userId) "+
                "order by p.projectName");
        emf.addNamedQuery(QRY_GET_PROJECT_FOR_USER_LIST_JSON, q);

        q = em.createQuery(
                "select p.id, p.projectName, p.description, case when wr.id is not null then 1 else 0 end  as canWrite "+
                        "from Project p left join p.writers wr on (wr.id=:userId) "+
                        "where p.id = :projectID "+
                        "order by p.projectName");
        emf.addNamedQuery(QRY_GET_PROJECT_DETAILS_FOR_USER_JSON, q);

        q = em.createQuery("select count(o) from Project o where o.projectName = :projectName and o.id != :projectId");
        emf.addNamedQuery(QRY_GET_PROJECT_COUNT_BY_PROJECTNAME, q);

        q = em.createQuery(
                "select count(o) " +
                "from ProjectWriter o " +
                "where o.projectId=:projectId and o.userId=:userId");
        emf.addNamedQuery(QRY_GET_COUNT_WRITEABLE_PROJECTS_BY_USERID_AND_PROJECTID, q);

        q = em.createQuery("select count(o) from Update o where o.projectId=:projectId");
        emf.addNamedQuery(QRY_GET_UPDATE_COUNT_OF_PROJECT, q);
    }

    public String getProjectDetailsJson(int projectId, User caller) throws DAOException {
        if (projectId == 0)
            throw new DAOIllegalArgumentException("Передан id проекта равный 0", MSG_ID_PROJECT_IS_ZERO_ERROR_CODE);

        try {
            Object[] data;
            if (caller == null) {
                data = em.createNamedQuery(QRY_GET_PROJECT_DETAILS_FOR_USER_JSON, Object[].class)
                        .setParameter("userId", 0)
                        .setParameter("projectId", projectId)
                        .getSingleResult();
            } else if (caller.getUserType() == UserType.ADMIN) {
                data = em.createNamedQuery(QRY_GET_PROJECT_DETAILS_JSON, Object[].class)
                        .setParameter("projectId", projectId)
                        .getSingleResult();
            } else {
                data = em.createNamedQuery(QRY_GET_PROJECT_DETAILS_FOR_USER_JSON, Object[].class)
                        .setParameter("userId", caller.getId())
                        .setParameter("projectId", projectId)
                        .getSingleResult();
            }
            return MyJsonBuilder.buildJsonObject(QRY_GET_PROJECT_LIST_JSON_FIELD_NAMES, data);
        } catch (NoResultException e) {
            throw new DAONotFoundException("Не найден проект с id "+projectId, MSG_PROJECT_NOT_FOUND_ERROR_CODE);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    @PermitAll
    public String getProjectListJson(User caller) throws DAOException {
        try {
            List<Object[]> data;
            if (caller == null) {
                data = em.createNamedQuery(QRY_GET_PROJECT_FOR_USER_LIST_JSON, Object[].class)
                        .setParameter("userId", 0)
                        .getResultList();
            } else if (caller.getUserType() == UserType.ADMIN) {
                data = em.createNamedQuery(QRY_GET_ALL_PROJECT_LIST_JSON, Object[].class).getResultList();
            } else {
                data = em.createNamedQuery(QRY_GET_PROJECT_FOR_USER_LIST_JSON, Object[].class)
                                        .setParameter("userId", caller.getId())
                                        .getResultList();
            }
            return MyJsonBuilder.buildJsonArray(QRY_GET_PROJECT_LIST_JSON_FIELD_NAMES, data);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    private boolean isExistsProjectByProjectName(String projectName, int projectId) {
        return em.createNamedQuery(QRY_GET_PROJECT_COUNT_BY_PROJECTNAME, Long.class)
                .setParameter("projectName", projectName)
                .setParameter("projectId", projectId)
                .getSingleResult()>0;
    }

    @RolesAllowed("admin")
    public int addProject(String projectName, String description) throws DAOException {
        if (projectName == null || projectName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано наименование проекта (project_name)",
                    MSG_PROJECTNAME_IS_EMPTY_ERROR_CODE);
        if (description == null || description.isEmpty())
            throw new DAOIllegalArgumentException("Не задано описание проекта (description)",
                    MSG_DESC_IS_EMPTY_ERROR_CODE);

        if (isExistsProjectByProjectName(projectName, 0))
            throw new DAOAlreadyExistsException("Проект с таким наименованием (project_name) уже существует",
                    MSG_PROJECT_WITH_SAME_PROJECTNAME_EXISTS_ERROR_CODE);

        try {
            Project newProject = new Project();

            newProject.setProjectName(projectName);
            newProject.setDescription(description);

            em.persist(newProject);

            return newProject.getId();
        } catch (Exception e) {
            throw new DAOException(e.getMessage());
        }
    }

    public boolean isUserCanChangeProject(int projectId, int userId) {
        return em.createNamedQuery(QRY_GET_COUNT_WRITEABLE_PROJECTS_BY_USERID_AND_PROJECTID, Long.class)
                .setParameter("projectId", projectId)
                .setParameter("userId", userId)
                .getSingleResult()>0;
    }

    @RolesAllowed({"user", "admin"})
    public void changeProject(int projectId, String projectName, String description, User caller) throws DAOException {
        if (projectName == null || projectName.isEmpty())
            throw new DAOIllegalArgumentException("Не задано наименование проекта (project_name)",
                    MSG_PROJECTNAME_IS_EMPTY_ERROR_CODE);

        if (description == null || description.isEmpty())
            throw new DAOIllegalArgumentException("Не задано описание проекта (description)",
                    MSG_DESC_IS_EMPTY_ERROR_CODE);

        Project project = em.find(Project.class, projectId);
        if (project == null)
            throw new DAONotFoundException("Не найден проект с ID "+String.valueOf(projectId), MSG_PROJECT_NOT_FOUND_ERROR_CODE);

        if (caller.getUserType() == UserType.USER && !isUserCanChangeProject(projectId, caller.getId()))
            throw new DAOForbiddenException("Вы не имеете прав на изменение проекта с ID "+String.valueOf(projectId),
                        MSG_FORBIDDEN_CHANGE_PROJECT_ERROR_CODE);

        if (isExistsProjectByProjectName(projectName, projectId))
            throw new DAOAlreadyExistsException("Проект с таким наименованием (project_name) уже существует",
                    MSG_PROJECT_WITH_SAME_PROJECTNAME_EXISTS_ERROR_CODE);

        try {
            project.setProjectName(projectName);
            project.setDescription(description);

            em.merge(project);
        } catch (Exception e) {
            throw new DAOException(e.getMessage());
        }
    }

    private boolean isProjectHaveUpdates(int projectId) {
        return em.createNamedQuery(QRY_GET_UPDATE_COUNT_OF_PROJECT, Long.class)
                .setParameter("projectId", projectId)
                .getSingleResult()>0;
    }

    @RolesAllowed({"admin", "user"})
    public void removeProject(int projectId, User caller) throws DAOException {
        Project project = em.find(Project.class, projectId);
        if (project == null)
            throw new DAONotFoundException("Не найден проект с ID "+String.valueOf(projectId),
                    MSG_PROJECT_NOT_FOUND_ERROR_CODE);

        if (caller.getUserType() == UserType.USER && !isUserCanChangeProject(projectId, caller.getId()))
            throw new DAOForbiddenException("У вас нет прав на удаление проекта с ID "+String.valueOf(projectId),
                    MSG_FORBIDDEN_CHANGE_PROJECT_ERROR_CODE);

        if (isProjectHaveUpdates(projectId))
            throw new DAOException("Данный проект содержит обновления. Очистите обновления и повторите попытку удаления проекта",
                    MSG_PROJECT_HAVE_UPDATES_ERROR_CODE);

        try {
            em.remove(project);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }
}
