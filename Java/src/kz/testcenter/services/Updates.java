package kz.testcenter.services;

import kz.testcenter.HibernateUtil;
import org.hibernate.Query;
import org.hibernate.Session;

import javax.annotation.Resource;
import javax.ws.rs.*;
import javax.ws.rs.Path;
import javax.ws.rs.core.*;
import javax.xml.bind.annotation.*;

import kz.testcenter.entities.*;

import org.apache.commons.lang3.math.NumberUtils;
import org.hibernate.Transaction;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.util.Date;
import java.util.List;
import java.util.Properties;

@XmlAccessorType(XmlAccessType.NONE)
@XmlRootElement(name = "updates")
@Path("/")
public class Updates {
  private static String updatesPath;
  private static Date dateTime = new Date();

  @Context
  private Request request;

  static {
    InputStream inStream = Thread.currentThread().getContextClassLoader().getResourceAsStream("config.properties");
    Properties config = new Properties();
    try {
      config.load(inStream);
      inStream.close();
    } catch (IOException ex)
    {
      ex.printStackTrace();
    }
    updatesPath = config.getProperty("updatesPath");
  }

  @XmlElement(name = "projectList")
  private String projectsUri = "/updates/rest/projects?receiverId={receiverId: [0-9;a-z;A-Z]}";
  public String getProjectsUri(){
    return this.projectsUri;
  }
  public void setProjectsUri(String uri){
    this.projectsUri = uri;
  }

  @XmlElement(name = "projectUpdateList")
  private String updatesUri = "/updates/rest/updates?projectName={projectName: [0-9;a-z;A-Z]}&receiverId={receiverId: [0-9;a-z;A-Z]}";
  public String getUpdatesUri(){
    return this.updatesUri;
  }
  public void setUpdatesUri(String uri){
    this.updatesUri = uri;
  }

  @XmlElement(name = "update")
  private String updateUri = "/updates/rest/update?updateId={updateId: [0-9]}&receiverId={receiverId: [0-9;a-z;A-Z]}";
  public String getUpdateUri(){
    return this.updateUri;
  }
  public void setUpdateUri(String uri){
    this.updateUri = uri;
  }

  @GET
  @Produces("application/xml")
  public Updates getServiceInfo(){
    return new Updates();
  }

  @HEAD
  @Path("isServiceAlive")
  public Response isServiceAlive()
  {
    return Response.ok().build();
  }

  @GET
  @Path("projects")
  @Produces("application/json;charset=UTF-8")
  public Response getProjectList(@QueryParam("receiverId") String receiverId) {
    if (receiverId == null || receiverId.isEmpty())
      return Response.status(Response.Status.BAD_REQUEST).
                      entity("Must be specified \"receiverId\"").
                      type(MediaType.TEXT_PLAIN_TYPE).
                      build();

    Session session = HibernateUtil.getSession();
    try {
      List<enProject> enProjects = session.createQuery("from enProject").list();
      if (enProjects.size()>0)
        return Response.ok(enProjects).build();
      else
        return Response.noContent().build();
    }
    finally {
      session.close();
    }
  }

  @GET
  @Path("updates")
  @Produces("application/json;charset=UTF-8")
  public Response getUpdateList(@QueryParam("projectName") String projectName,
                                           @QueryParam("receiverId") String receiverId) {
    if (projectName == null || projectName.isEmpty())
      return Response.status(Response.Status.BAD_REQUEST).
              entity("Must be specified queryParam \"projectName\"").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();
    if (receiverId == null || receiverId.isEmpty())
      return Response.status(Response.Status.BAD_REQUEST).
              entity("Must be specified queryParam \"receiverId\"").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();

    Session session = HibernateUtil.getSession();

    try {
      @SuppressWarnings("unchecked")
      Integer idProject = (Integer) session.createQuery("select id from enProject where projectName=:projectName").
              setString("projectName", projectName).uniqueResult();

      if (idProject != null) {
        List<enUpdate> updates = session.createQuery("from enUpdate where idProject=:Id").
                setInteger("Id", idProject).list();
        if (updates.size()>0)
          return Response.ok(updates).build();
        else
          return Response.noContent().build();
      } else return Response.status(Response.Status.NOT_FOUND).build();
    }
    finally {
      session.close();
    }
  }

  @GET
  @Path("update")
  @Produces(MediaType.APPLICATION_OCTET_STREAM)
  public Response getUpdate(@QueryParam("updateId") String updateId,
                            @QueryParam("receiverId") String receiverId)
  {
    if (updateId == null)
      return Response.status(Response.Status.BAD_REQUEST).
              entity("Must be specified \"updateId\"").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();
    if (receiverId == null || receiverId.isEmpty())
      return Response.status(Response.Status.BAD_REQUEST).
              entity("Must be specified \"updateId\"").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();

    if (receiverId.length()>20)
      return Response.status(Response.Status.BAD_REQUEST).
              entity("ReceiverId should not be more than 20 characters").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();

    if (!NumberUtils.isNumber(updateId))
      return Response.status(Response.Status.BAD_REQUEST).
              entity("Incorrect value of \"updateId\" - " + updateId + " (must be only digits)").
              type(MediaType.TEXT_PLAIN_TYPE).
              build();
    int updId = Integer.parseInt(updateId);

    Session session = HibernateUtil.getSession();

    try
    {
      Object[] enUpd = (Object[])session.createQuery("select filePath, fileName from enUpdate where id=:id").
              setInteger("id", updId).uniqueResult();

      if (enUpd == null || enUpd.length == 0)
        return Response.status(Response.Status.NOT_FOUND).
                entity("Record with ID " + updateId + " not found in database").
                type(MediaType.TEXT_PLAIN_TYPE).
                build();
      File file;
      StringBuilder filePath = new StringBuilder(updatesPath);
      if (enUpd[0] == null || ((String)enUpd[0]).isEmpty())
        filePath.append((String)enUpd[1]);
       else
        filePath.append((String)enUpd[0]).append("/").append((String)enUpd[1]);

      if (File.separator.equals("\\"))
        file = new File(filePath.toString().replaceAll("/", "\\\\"));
      else
        file = new File(filePath.toString());

      if (!file.exists())
        return Response.status(Response.Status.INTERNAL_SERVER_ERROR).
                entity("File by ID " + updateId + " not found").
                type(MediaType.TEXT_PLAIN_TYPE).
                build();

      Response.ResponseBuilder response;

      if (request.getMethod().equals("GET")) {
        Transaction transaction = session.beginTransaction();

        enUpdateReceiver updateReceiver = new enUpdateReceiver();
        updateReceiver.setIdReceiver(receiverId);
        updateReceiver.setIdUpdate(updId);
        session.save(updateReceiver);

        transaction.commit();

        response = Response.ok((Object) file);
      } else
        response = Response.ok();


      response.header("Content-Length", file.length());
      response.header("Content-Disposition", "attachment;filename=\""+(String)enUpd[1]+"\"");

      return response.build();

    } finally {
      session.close();
    }
  }
}
