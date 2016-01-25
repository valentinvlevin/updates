package kz.testcenter;

import org.hibernate.HibernateException;
import org.hibernate.SessionFactory;
import org.hibernate.Session;
import org.hibernate.Query;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.cfg.Configuration;
import org.hibernate.metadata.ClassMetadata;
import org.hibernate.service.ServiceRegistry;

import java.util.Map;

public class HibernateUtil {
  private static SessionFactory ourSessionFactory;

  public static SessionFactory getSessionFactory() {
    if (ourSessionFactory == null) {
      // loads configuration and mappings
      Configuration configuration = new Configuration().configure();
      ServiceRegistry serviceRegistry
              = new StandardServiceRegistryBuilder()
              .applySettings(configuration.getProperties()).build();

      // builds a session factory from the service registry
      ourSessionFactory = configuration.buildSessionFactory(serviceRegistry);
    }

    return ourSessionFactory;
  }

    public static Session getSession() throws HibernateException {
        return getSessionFactory().openSession();
    }

    public static void main(final String[] args) throws Exception {
        final Session session = getSession();
        try {
            System.out.println("querying all the managed entities...");
            final Map metadataMap = session.getSessionFactory().getAllClassMetadata();
            for (Object key : metadataMap.keySet()) {
                final ClassMetadata classMetadata = (ClassMetadata) metadataMap.get(key);
                final String entityName = classMetadata.getEntityName();
                final Query query = session.createQuery("from " + entityName);
                System.out.println("executing: " + query.getQueryString());
                for (Object o : query.list()) {
                    System.out.println("  " + o);
                }
            }
        } finally {
            session.close();
        }
    }
}
