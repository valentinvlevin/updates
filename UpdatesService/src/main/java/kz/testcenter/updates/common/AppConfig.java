package kz.testcenter.updates.common;

import javax.ejb.Singleton;
import javax.ejb.Startup;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

@Startup
@Singleton
public class AppConfig {
    private static String updatesPath;

    static {
        Properties config = new Properties();
        try (
                InputStream inStream = Thread.currentThread().getContextClassLoader().getResourceAsStream("config.properties");
        ) {
            config.load(inStream);
            updatesPath = config.getProperty("updatesPath");
        } catch (IOException e) {

        }
    }

    public static String getUpdatesPath() {
        return AppConfig.updatesPath;
    }
}