package kz.testcenter.updates.services;

import kz.testcenter.updates.common.UserProvider;
import kz.testcenter.updates.db.dao.UpdateDAO;
import kz.testcenter.updates.db.exceptions.*;

import javax.annotation.security.PermitAll;
import javax.annotation.security.RolesAllowed;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;
import java.io.File;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

import org.jboss.resteasy.plugins.providers.multipart.InputPart;
import org.jboss.resteasy.plugins.providers.multipart.MultipartFormDataInput;
import org.apache.commons.lang3.math.NumberUtils;

@Path("/updates")
@Produces("application/json;charset=UTF-8")
@Stateless
public class UpdatesService {
    @Inject
    private UpdateDAO updateDAO;
    @Inject
    private UserProvider userProvider;
    @Context
    private UriInfo uriInfo;

    @GET
    @Path("/{project_id}")
    @PermitAll
    public Response getUpdateList(@PathParam("project_id") int projectId) {
        try {
            return Response.ok(updateDAO.getUpdatesListJson(projectId, userProvider.getCurrentUser())).build();
        } catch (DAOForbiddenException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getExceptionMessage()).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @GET
    @Path("/{update_id}/update_info")
    @PermitAll
    public Response getUpdateInfo(@PathParam("update_id") int updateId) {
        try {
            String result = updateDAO.getUpdateInfo(updateId, userProvider.getCurrentUser());
            return Response.ok(result).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.toString()).build();
        }
    }

    @GET
    @Path("/{update_id}/download")
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    @PermitAll
    public Response getUpdateFile(@PathParam("update_id") int updateId,
                              @QueryParam("receiver_id") String receiverId)
    {
        try {
            if (receiverId == null || receiverId.isEmpty())
                throw new DAOIllegalArgumentException("Не указан ID получателя (receiver_id)",
                        updateDAO.MSG_UPDATE_RECEIVER_NOT_FOUND_ERROR_CODE);

            File downloadedFile = updateDAO.getUpdateFile(updateId, receiverId);
            Response.ResponseBuilder response;
            response = Response.ok(downloadedFile);
            response.header("Content-Length", downloadedFile.length());
            response.header("Content-Disposition", "attachment;filename=\"" + Paths.get(downloadedFile.getPath()).getFileName() + "\"");

            return response.build();

        } catch(DAOException e) {
            return Response.serverError().entity(e.toString()).build();
        }
    }

    private String getFileName(MultivaluedMap<String, String> header) {
        String[] contentDisposition = header.getFirst("Content-Disposition").split(";");
        for (String fileName : contentDisposition) {
            if (fileName.trim().startsWith("filename")) {
                String[] name = fileName.split("=");
                String finalfileName = name[1].trim().replaceAll("\"", "");
                return finalfileName;
            }
        }
        return "";
    }

    @POST
    @Path("/{project_id}")
    @RolesAllowed({"user", "admin"})
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response addUpdate(
            @PathParam("project_id") int projectId,
            MultipartFormDataInput input)
    {
        try {
            Map<String, List<InputPart>> uploadForm = input.getFormDataMap();

            List<InputPart> inputPart = uploadForm.get("ord");
            if (inputPart == null || inputPart.size()!=1)
                throw new DAOIllegalArgumentException("Ошибка в значении поля ord", updateDAO.MSG_ORD_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String sOrd = inputPart.get(0).getBodyAsString();
            if (!NumberUtils.isNumber(sOrd))
                throw new DAOIllegalArgumentException("Значение поля ord должно содержать только цифры", updateDAO.MSG_ORD_INCORRECT_ERROR_CODE);
            short ord = Short.valueOf(sOrd);

            inputPart = uploadForm.get("description");
            if (inputPart == null || inputPart.size()!=1)
                throw new DAOIllegalArgumentException("Ошибка в значении поля description", updateDAO.MSG_DESCRIPTION_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String description = inputPart.get(0).getBodyAsString();

            inputPart = uploadForm.get("uploaded_file");
            if (inputPart == null)
                throw new DAOIllegalArgumentException("В запросе не найден файл", updateDAO.MSG_FILE_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String fileName = getFileName(inputPart.get(0).getHeaders());
            InputStream inputStream = inputPart.get(0).getBody(InputStream.class, null);

            int newId = updateDAO.addUpdate(projectId, fileName, description, ord, inputStream, userProvider.getCurrentUser());
            URI uri = uriInfo.getAbsolutePathBuilder().path(String.valueOf(newId)).build();
            return Response.created(uri).build();
        } catch (DAOForbiddenException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getExceptionMessage()).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e.getExceptionMessage()).build();
        } catch (DAOIllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getExceptionMessage()).build();
        } catch (DAOAlreadyExistsException e) {
            return Response.status(Response.Status.CONFLICT).entity(e.getExceptionMessage()).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @PUT
    @Path("/{update_id}")
    @RolesAllowed({"user", "admin"})
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    public Response changeUpdateData(
            @PathParam("update_id") int updateId,
            MultipartFormDataInput input)
    {

        try {
            Map<String, List<InputPart>> uploadForm = input.getFormDataMap();

            List<InputPart> inputPart = uploadForm.get("ord");
            if (inputPart == null || inputPart.size()!=1)
                throw new DAOIllegalArgumentException("Ошибка в значении поля ord", updateDAO.MSG_ORD_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String sOrd = inputPart.get(0).getBodyAsString();
            if (!NumberUtils.isNumber(sOrd))
                throw new DAOIllegalArgumentException("Значение поля ord должно содержать только цифры", updateDAO.MSG_ORD_INCORRECT_ERROR_CODE);
            short ord = Short.valueOf(sOrd);

            inputPart = uploadForm.get("description");
            if (inputPart == null || inputPart.size()!=1)
                throw new DAOIllegalArgumentException("Ошибка в значении поля description", updateDAO.MSG_DESCRIPTION_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String description = inputPart.get(0).getBodyAsString();

            inputPart = uploadForm.get("uploaded_file");
            if (inputPart == null)
                throw new DAOIllegalArgumentException("В запросе не найден файл", updateDAO.MSG_FILE_NOT_FOUND_IN_REQUEST_ERROR_CODE);
            String fileName = getFileName(inputPart.get(0).getHeaders());
            InputStream istream = inputPart.get(0).getBody(InputStream.class, null);

            updateDAO.changeUpdateData(updateId, fileName, description, ord, istream, userProvider.getCurrentUser());
            return Response.accepted().build();
        } catch (DAOForbiddenException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getExceptionMessage()).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e.getExceptionMessage()).build();
        } catch (DAOIllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getExceptionMessage()).build();
        } catch (DAOAlreadyExistsException e) {
            return Response.status(Response.Status.CONFLICT).entity(e.getExceptionMessage()).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @DELETE
    @Path("/{update_id}")
    @RolesAllowed({"user", "admin"})
    public Response changeUpdateData(@PathParam("update_id") int updateId)
    {
        try {
            updateDAO.removeUpdate(updateId, userProvider.getCurrentUser());
            return Response.noContent().build();
        } catch (DAOForbiddenException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getExceptionMessage()).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e.getExceptionMessage()).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }
}