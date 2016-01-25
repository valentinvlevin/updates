package kz.testcenter.updates.db.dao;

import kz.testcenter.updates.common.AppConfig;
import kz.testcenter.updates.common.MyJsonBuilder;
import kz.testcenter.updates.db.entities.Project;
import kz.testcenter.updates.db.entities.Update;
import kz.testcenter.updates.db.entities.UpdateReceiver;
import kz.testcenter.updates.db.entities.users.UpdateWriter;
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
import javax.persistence.Query;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Date;
import java.util.List;

import org.apache.commons.io.FileUtils;

@Singleton
@Startup
public class UpdateDAO {
    public final int MSG_COMMON_ERROR_CODE = 3000;
    private final int MSG_UPDATE_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+1;
    private final int MSG_PROJECT_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+8;

    private final int MSG_FORBIDDEN_CHANGE_UPDATE_ERROR_CODE = MSG_COMMON_ERROR_CODE+2;
    private final int MSG_FORBIDDEN_ADD_UPDATE_ERROR_CODE = MSG_COMMON_ERROR_CODE+9;
    private final int MSG_FORBIDDEN_DELETE_UPDATE_ERROR_CODE = MSG_COMMON_ERROR_CODE+10;

    private final int MSG_FILENAME_IS_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+4;
    private final int MSG_DESCRIPTION_IS_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+5;
    private final int MSG_ORD_IS_ZERO_ERROR_CODE = MSG_COMMON_ERROR_CODE+6;
    private final int MSG_FILE_WITH_SAME_ORD_IS_EXISTS_ERROR_CODE = MSG_COMMON_ERROR_CODE+7;

    private final int MSG_REQUEST_ID_EMPTY_ERROR_CODE = MSG_COMMON_ERROR_CODE+11;

    public final int MSG_DESCRIPTION_NOT_FOUND_IN_REQUEST_ERROR_CODE = MSG_COMMON_ERROR_CODE+12;
    public final int MSG_ORD_NOT_FOUND_IN_REQUEST_ERROR_CODE = MSG_COMMON_ERROR_CODE+13;
    public final int MSG_FILE_NOT_FOUND_IN_REQUEST_ERROR_CODE = MSG_COMMON_ERROR_CODE+13;
    public final int MSG_ORD_INCORRECT_ERROR_CODE = MSG_COMMON_ERROR_CODE+15;

    private final int MSG_UPDATE_FILE_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+16;

    public final int MSG_UPDATE_RECEIVER_NOT_FOUND_ERROR_CODE = MSG_COMMON_ERROR_CODE+17;

    private final String QRY_GET_UPDATE_LIST_TO_USER_JSON = "UpdatesDAO.getUpdateListToUserJson";
    private final String QRY_GET_UPDATE_LIST_TO_ADMIN_JSON = "UpdatesDAO.getUpdateListToAdminJson";
    private final String QRY_GET_UPDATE_BY_ID_TO_USER_JSON = "UpdatesDAO.getUpdateByIDToUserJson";
    private final String QRY_GET_UPDATE_BY_ID_TO_ADMIN_JSON = "UpdatesDAO.getUpdateByIDToAdminJson";
    private final String[] QRY_GET_UPDATE_LIST_JSON_FIELD_NAMES = {"id", "ord", "file_name", "file_size", "description", "add_date_time", "can_write"};

    private final String QRY_GET_UPDATE_COUNT_OF_PROJECT_WITH_ORD_COUNT = "UpdatesDAO.getUpdateCountOfProjectWithOrdCount";

    private final String QRY_GET_UPDATE_COUNT_BY_ID = "UpdateDAO.getUpdateCountByID";

    private final String QRY_GET_COUNT_WRITEABLE_UPDATES_BY_USERID_AND_UPDATEID = "UpdatesDAO.getCountWriteableUpdatesByUserIdAndUpdateId";

    @Inject
    private EntityManager em;

    @Inject
    private ProjectDAO projectDAO;

    @PostConstruct
    public void init() {
        EntityManagerFactory emf = em.getEntityManagerFactory();
        Query q;

        q = em.createQuery(
                "select o.id, o.ord, o.fileName, o.fileSize, o.description, o.addDateTime, 1 as canWrite "+
                "from Update o "+
                "where o.projectId=:projectId");
        emf.addNamedQuery(QRY_GET_UPDATE_LIST_TO_ADMIN_JSON, q);

        q = em.createQuery(
                "select u.id, u.ord, u.fileName, u.fileSize, u.description, u.addDateTime, " +
                " case when wr.id is not null then 1 else 0 end as canWrite "+
                "from Update u left join u.writers wr on (wr.id=:userId)"+
                "where (u.projectId=:projectId) ");
        emf.addNamedQuery(QRY_GET_UPDATE_LIST_TO_USER_JSON, q);

        q = em.createQuery(
                "select o.id, o.ord, o.fileName, o.fileSize, o.description, o.addDateTime, 1 as canWrite "+
                "from Update o "+
                "where o.id=:updateId");
        emf.addNamedQuery(QRY_GET_UPDATE_BY_ID_TO_ADMIN_JSON, q);

        q = em.createQuery(
                "select u.id, u.ord, u.fileName, u.fileSize, u.description, u.addDateTime, " +
                " case when wr.id is not null then 1 else 0 end as canWrite "+
                "from Update u left join u.writers wr on (wr.id=:userId) "+
                "where (u.id=:updateId) ");
        emf.addNamedQuery(QRY_GET_UPDATE_BY_ID_TO_USER_JSON, q);

        q = em.createQuery("select count(o) from Update o where o.projectId=:projectId and o.ord=:ord and id!=:updateId");
        emf.addNamedQuery(QRY_GET_UPDATE_COUNT_OF_PROJECT_WITH_ORD_COUNT, q);

        q = em.createQuery("select count(o) from UpdateWriter o where updateId=:updateId and userId=:userId");
        emf.addNamedQuery(QRY_GET_COUNT_WRITEABLE_UPDATES_BY_USERID_AND_UPDATEID, q);

        q = em.createQuery("select count(o) from Update o where id=:updateId");
        emf.addNamedQuery(QRY_GET_UPDATE_COUNT_BY_ID, q);
    }

    @PermitAll
    public String getUpdatesListJson(int projectId, User caller) throws DAOException {
        try {
            List<Object[]> data;
            if (caller  == null)
                data = em.createNamedQuery(QRY_GET_UPDATE_LIST_TO_USER_JSON, Object[].class)
                        .setParameter("projectId", projectId)
                        .setParameter("userId", 0)
                        .getResultList();
            else if (caller.getUserType() == UserType.USER)
                data = em.createNamedQuery(QRY_GET_UPDATE_LIST_TO_USER_JSON, Object[].class)
                        .setParameter("projectId", projectId)
                        .setParameter("userId", caller.getId())
                        .getResultList();
             else
                data = em.createNamedQuery(QRY_GET_UPDATE_LIST_TO_ADMIN_JSON, Object[].class)
                        .setParameter("projectId", projectId)
                        .getResultList();

            String result = MyJsonBuilder.buildJsonArray(QRY_GET_UPDATE_LIST_JSON_FIELD_NAMES, data);
            return result;
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }

    private boolean isUpdateExists(int updateId) {
        return em.createNamedQuery(QRY_GET_UPDATE_COUNT_BY_ID, Long.class)
                .setParameter("updateId", updateId)
                .getSingleResult()>0;
    }

    @PermitAll
    public String getUpdateInfo(int updateId, User caller) throws DAOException {
        try {
            if (!isUpdateExists(updateId))
                throw new DAONotFoundException("Не найдено обновление с ID "+String.valueOf(updateId),
                        MSG_UPDATE_NOT_FOUND_ERROR_CODE);

            Object[] data;
            if (caller == null)
                data = em.createNamedQuery(QRY_GET_UPDATE_BY_ID_TO_USER_JSON, Object[].class)
                        .setParameter("updateId", updateId)
                        .setParameter("userId", 0)
                        .getSingleResult();
            else if (caller.getUserType() == UserType.ADMIN)
                data = em.createNamedQuery(QRY_GET_UPDATE_BY_ID_TO_ADMIN_JSON, Object[].class)
                        .setParameter("updateId", updateId)
                        .getSingleResult();
            else
                data = em.createNamedQuery(QRY_GET_UPDATE_BY_ID_TO_USER_JSON, Object[].class)
                        .setParameter("updateId", updateId)
                        .setParameter("userId", caller.getId())
                        .getSingleResult();

            return MyJsonBuilder.buildJsonObject(QRY_GET_UPDATE_LIST_JSON_FIELD_NAMES, data);
        } catch (Exception e) {
            throw new DAOException(e.toString(), MSG_COMMON_ERROR_CODE);
        }
    }

    private Path getUpdateDirPath(int projectId, int updateId) {
        return Paths.get(AppConfig.getUpdatesPath(), String.valueOf(projectId), String.valueOf(updateId));
    }

    private Path getUpdateFilePath(int projectId, int updateId, String fileName) {
        return Paths.get(getUpdateDirPath(projectId, updateId).toString(), fileName);
    }

    @PermitAll
    public File getUpdateFile(int updateId, String receiverId) throws DAOException {
        try {
            Update update = em.find(Update.class, updateId);

            if (update == null)
                throw new DAONotFoundException("Не найдено обновление с ID "+String.valueOf(updateId),
                        MSG_UPDATE_NOT_FOUND_ERROR_CODE);

            Path updateFilePath = getUpdateFilePath(update.getProjectId(), update.getId(), update.getFileName());
            if (!Files.exists(updateFilePath))
                throw new DAONotFoundException("Не найден файл обновления с ID "+String.valueOf(updateId),
                        MSG_UPDATE_FILE_NOT_FOUND_ERROR_CODE);

            UpdateReceiver newUpdateReceiver = new UpdateReceiver();

            newUpdateReceiver.setUpdateId(updateId);
            newUpdateReceiver.setReceiverId(receiverId);
            em.persist(newUpdateReceiver);

            return updateFilePath.toFile();
        } catch (Exception e) {
            throw new DAOException(e.toString(), MSG_COMMON_ERROR_CODE);
        }
    }

    private boolean isHaveUpdateWithSameOrd(int projectId, short ord, int updateId) {
        return em.createNamedQuery(QRY_GET_UPDATE_COUNT_OF_PROJECT_WITH_ORD_COUNT, Long.class)
                .setParameter("projectId", projectId)
                .setParameter("ord", ord)
                .setParameter("updateId", updateId)
                .getSingleResult()>0;
    }

    private int saveFile(InputStream uploadedFile, Path filePath, String fileName) throws IOException {
        if (Files.exists(filePath))
            FileUtils.cleanDirectory(filePath.toFile());
        else
            Files.createDirectories(filePath);

        OutputStream outputStream = new FileOutputStream(Paths.get(filePath.toString(), fileName).toFile());
        int read = 0;
        int fileSize = 0;
        byte[] bytes = new byte[1024];

        while ((read = uploadedFile.read(bytes)) != -1) {
            outputStream.write(bytes, 0, read);
            fileSize += read;
        }
        outputStream.flush();
        outputStream.close();

        return fileSize;
    }

    @RolesAllowed({"admin", "user"})
    public int addUpdate(int projectId, String fileName, String description, short ord, InputStream uploadedFile, User caller)
        throws DAOException
    {
        Project project = em.find(Project.class, projectId);
        if (project == null)
            throw new DAONotFoundException("Не найден проект с ID "+String.valueOf(projectId), MSG_PROJECT_NOT_FOUND_ERROR_CODE);
        if (caller.getUserType() == UserType.USER && !projectDAO.isUserCanChangeProject(projectId, caller.getId()))
            throw new DAONotFoundException("У вас нет прав на добавление обновлений в проект с ID "+String.valueOf(projectId),
                    MSG_FORBIDDEN_ADD_UPDATE_ERROR_CODE);
        if (fileName == null || fileName.isEmpty())
            throw new DAOIllegalArgumentException("Не задан имя файла (file_name)", MSG_FILENAME_IS_EMPTY_ERROR_CODE);
        if (description == null || description.isEmpty())
            throw new DAOIllegalArgumentException("Не задано описание обновления (description)", MSG_DESCRIPTION_IS_EMPTY_ERROR_CODE);
        if (ord == 0)
            throw new DAOIllegalArgumentException("Не указан порядновый номер обновления (ord)", MSG_ORD_IS_ZERO_ERROR_CODE);
        if (isHaveUpdateWithSameOrd(projectId, ord, 0))
            throw new DAOAlreadyExistsException("В проекте с ID "+String.valueOf(projectId)+" уже имеется обновление с порядковым номером "+String.valueOf(ord),
                    MSG_FILE_WITH_SAME_ORD_IS_EXISTS_ERROR_CODE);

        try {
            Update newUpdate = new Update();
            newUpdate.setProjectId(projectId);
            newUpdate.setFileName(fileName);
            newUpdate.setDescription(description);
            newUpdate.setOrd(ord);
            newUpdate.setAddDateTime(new Date());
            newUpdate.setFileSize(0);

            em.persist(newUpdate);

            UpdateWriter newUpdateWriter = new UpdateWriter();
            newUpdateWriter.setUpdateId(newUpdate.getId());
            newUpdateWriter.setUserId(caller.getId());

            em.persist(newUpdateWriter);

            newUpdate.setFileSize(saveFile(uploadedFile, getUpdateDirPath(projectId, newUpdate.getId()), fileName));
            em.merge(newUpdate);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }

        return 0;
    }

    public boolean isUserCanChangeUpdate(int updateId, int userId) {
        return em.createNamedQuery(QRY_GET_COUNT_WRITEABLE_UPDATES_BY_USERID_AND_UPDATEID, Long.class)
                .setParameter("updateId", updateId)
                .setParameter("userId", userId)
                .getSingleResult()>0;
    }

    @RolesAllowed({"user", "admin"})
    public void changeUpdateData(int updateId, String fileName, String description, short ord, InputStream uploadedFile, User caller)
        throws DAOException
    {
        Update update = em.find(Update.class, updateId);
        if (update == null)
            throw new DAONotFoundException("Не найден обновление с ID "+String.valueOf(updateId), MSG_UPDATE_NOT_FOUND_ERROR_CODE);
        if (caller.getUserType() == UserType.USER && !isUserCanChangeUpdate(updateId, caller.getId()))
            throw new DAONotFoundException("У вас нет прав на изменение обновления с ID "+String.valueOf(updateId),
                    MSG_FORBIDDEN_CHANGE_UPDATE_ERROR_CODE);
        if (fileName == null || fileName.isEmpty())
            throw new DAOIllegalArgumentException("Не задан имя файла (file_name)", MSG_FILENAME_IS_EMPTY_ERROR_CODE);
        if (description == null || description.isEmpty())
            throw new DAOIllegalArgumentException("Не задано описание обновления (description)", MSG_DESCRIPTION_IS_EMPTY_ERROR_CODE);
        if (ord == 0)
            throw new DAOIllegalArgumentException("Не указан порядновый номер обновления (ord)", MSG_ORD_IS_ZERO_ERROR_CODE);
        if (isHaveUpdateWithSameOrd(update.getProjectId(), ord, updateId))
            throw new DAOAlreadyExistsException("В проекте с ID "+String.valueOf(update.getProjectId())+
                    " уже имеется обновление с порядковым номером "+String.valueOf(ord),
                    MSG_FILE_WITH_SAME_ORD_IS_EXISTS_ERROR_CODE);

        try {
            update.setFileName(fileName);
            update.setDescription(description);
            update.setOrd(ord);

            update.setFileSize(saveFile(uploadedFile, getUpdateDirPath(update.getProjectId(), update.getId()), fileName));

            em.merge(update);
        } catch (Exception e) {
            throw new DAOException(e.toString(), MSG_COMMON_ERROR_CODE);
        }
    }

    @RolesAllowed({"user", "admin"})
    public void removeUpdate(int updateId, User caller) throws DAOException {
        Update update = em.find(Update.class, updateId);
        if (update  == null)
            throw new DAONotFoundException("Не найдено обновление с ID "+String.valueOf(updateId), MSG_UPDATE_NOT_FOUND_ERROR_CODE);

        if (caller.getUserType() == UserType.USER && !isUserCanChangeUpdate(updateId, caller.getId()))
            throw new DAOForbiddenException("У вас нет прав на удаление обновления с ID "+String.valueOf(updateId),
                    MSG_FORBIDDEN_DELETE_UPDATE_ERROR_CODE);

        try {
            em.remove(update);
        } catch (Exception e) {
            throw new DAOException(e.getMessage(), MSG_COMMON_ERROR_CODE);
        }
    }
}
