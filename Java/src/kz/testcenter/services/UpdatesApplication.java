package kz.testcenter.services;

import javax.ws.rs.ApplicationPath;
import javax.ws.rs.core.Application;
import java.util.HashSet;
import java.util.Set;

@ApplicationPath("/updates")
public class UpdatesApplication extends Application
{
  HashSet<Object> singletons = new HashSet<Object>();

  public UpdatesApplication()
  {
    singletons.add(new Updates());
  }

  @Override
  public Set<Class<?>> getClasses() {
    HashSet<Class<?>> set = new HashSet<Class<?>>();
    return set;
  }

  @Override
  public Set<Object> getSingletons() {
    return singletons;
  }
}
