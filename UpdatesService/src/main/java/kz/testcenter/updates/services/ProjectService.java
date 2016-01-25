package kz.testcenter.updates.services;

import kz.testcenter.updates.common.UserProvider;
import kz.testcenter.updates.db.dao.ProjectDAO;
import kz.testcenter.updates.db.exceptions.*;
import kz.testcenter.updates.services.datatypes.dtProject;

import javax.annotation.security.PermitAll;
import javax.annotation.security.RolesAllowed;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;
import java.net.URI;

@Path("/projects")
@Produces("application/json;charset=UTF-8")
@Stateless
public class ProjectService {
    @Inject
    private ProjectDAO projectDAO;

    @Inject
    private UserProvider userProvider;

    @Context
    private UriInfo uriInfo;

    @GET
    @RolesAllowed({"admin", "user"})
    public Response getProjectList() {
        try {
            return Response.ok(projectDAO.getProjectListJson(userProvider.getCurrentUser())).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @POST
    @RolesAllowed("admin")
    @Consumes("application/x-www-form-urlencoded;charset=UTF-8")
    public Response addProject(
            @FormParam("projectName") String projectName,
            @FormParam("description") String description)
    {
        try {
            int newId = projectDAO.addProject(projectName, description);
            URI uri = uriInfo.getAbsolutePathBuilder().path(String.valueOf(newId)).build();
            return Response.created(uri).entity(newId).build();
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

    @GET
    @Path("{projectId}")
    @RolesAllowed({"admin", "user"})
    public Response getProjectDetails(@PathParam("projectId") int projectId) {
        try {
            String result = projectDAO.getProjectDetailsJson(projectId, userProvider.getCurrentUser());
            return Response.ok().entity(result).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e).build();
        } catch (DAOIllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e).build();
        } catch (Exception e) {
            return Response.serverError().entity(e).build();
        }
    }

    @PUT
    @Path("/{project_id}")
    @RolesAllowed({"admin", "user"})
    @Consumes("application/x-www-form-urlencoded;charset=UTF-8")
    public Response changeProject(
            @PathParam("project_id") int projectId,
            @FormParam("projectName") String projectName,
            @FormParam("description") String description
            )

    {
        try {
            projectDAO.changeProject(projectId, projectName, description, userProvider.getCurrentUser());
            return Response.accepted().build();
        } catch (DAOIllegalArgumentException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getExceptionMessage()).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e.getExceptionMessage()).build();
        } catch (DAOForbiddenException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getExceptionMessage()).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(new DAOException(e.getMessage(), 0)).build();
        }
    }

    @DELETE
    @Path("/{project_id}")
    @RolesAllowed({"admin", "user"})
    public Response removeProject(@PathParam("project_id") int projectId){
        try {
            projectDAO.removeProject(projectId, userProvider.getCurrentUser());
            return Response.noContent().build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }
}
