package kz.testcenter.updates.services;

import kz.testcenter.updates.common.UserProvider;
import kz.testcenter.updates.db.dao.UserDAO;
import kz.testcenter.updates.db.entities.users.User;
import kz.testcenter.updates.db.exceptions.DAOAlreadyExistsException;
import kz.testcenter.updates.db.exceptions.DAOException;
import kz.testcenter.updates.db.exceptions.DAOIllegalArgumentException;
import kz.testcenter.updates.db.exceptions.DAONotFoundException;
import org.jboss.resteasy.spi.HttpRequest;
import org.keycloak.KeycloakSecurityContext;
import org.keycloak.representations.AccessToken;

import javax.annotation.security.PermitAll;
import javax.annotation.security.RolesAllowed;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;
import java.net.HttpCookie;
import java.net.URI;

@Stateless
@Path("/users")
@Produces("application/json;charset=UTF-8")
public class UsersService {
    @Inject
    private UserDAO userDAO;

    @Inject
    private UserProvider userProvider;

    @Context
    private UriInfo uriInfo;

    @Context
    private HttpRequest httpRequest;

    @Context
    private HttpCookie httpCookie;

    @GET
    @PermitAll
    public Response getUserList() {
        try {
            String result = userDAO.getUserListJson();
            return Response.ok(result).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @GET
    @PermitAll
    @Path("/{user_id}")
    public Response getUser(@PathParam("user_id") int userId) {
        try {
            String result = userDAO.getUserById(userId);
            return Response.ok(result).build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e).build();
        } catch (Exception e) {
            return Response.serverError().entity(e).build();
        }
    }

    @POST
    @RolesAllowed("admin")
    public Response addUser(
            @FormParam("user_name") String userName,
            @FormParam("user_display_name") String userDisplayName,
            @FormParam("password") String password) {
        try {
            int newId = userDAO.addUser(userName, userDisplayName, password);
            URI uri = uriInfo.getAbsolutePathBuilder().path(String.valueOf(newId)).build();
            return Response.created(uri).build();
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
    @Path("/{user_id}")
    @RolesAllowed({"admin", "user"})
    public Response changeUserData(
            @PathParam("user_id") int userId,
            @FormParam("user_name") String userName,
            @FormParam("user_display_name") String userDisplayName,
            @FormParam("password") String password)
    {
        try {
            userDAO.changeUserData(userId, userName, userDisplayName, password, userProvider.getCurrentUser());
            return Response.accepted().build();
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
    @Path("/{user_id}")
    @RolesAllowed("admin")
    public Response removeUser(@PathParam("user_id") int userId) {
        try {
            userDAO.removeUser(userId);
            return Response.noContent().build();
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).entity(e.getExceptionMessage()).build();
        } catch (Exception e) {
            return Response.serverError().entity(e.getMessage()).build();
        }
    }

    @POST
    @PermitAll
    @Path("/login")
    public Response login() {
        try {
            User user  = userProvider.getCurrentUser();
            if (user != null) {
                String result = userDAO.getUserById(user.getId());

                NewCookie cookie = new NewCookie("id", String.valueOf(user.getId()));

                return Response.ok(result).cookie(cookie).build();
            } else {
                return Response.status(Response.Status.UNAUTHORIZED).build();
            }
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity(e).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e).build();
        } catch (Exception e) {
            return Response.serverError().entity(e).build();
        }
    }

    @GET
    @PermitAll
    @Path("/me")
    public Response getUserData() {
        try {
            if (httpCookie != null) {
                httpCookie.getValue();
            }
            User user  = userProvider.getCurrentUser();
            if (user != null) {
                String result = userDAO.getUserById(user.getId());

                return Response.ok(result).cookie().build();
            } else {
                return Response.status(Response.Status.UNAUTHORIZED).build();
            }
        } catch (DAONotFoundException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity(e).build();
        } catch (DAOException e) {
            return Response.serverError().entity(e).build();
        } catch (Exception e) {
            return Response.serverError().entity(e).build();
        }
    }

}
