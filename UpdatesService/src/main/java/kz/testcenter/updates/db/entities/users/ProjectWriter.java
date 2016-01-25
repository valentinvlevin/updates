package kz.testcenter.updates.db.entities.users;

import javax.persistence.*;

@Entity
@Table(name = "project_writers", schema = "public")
public class ProjectWriter {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    public int getId() {
        return this.id;
    }
    public void setId(int id) {
        this.id = id;
    }
    private int id;

    @Column(name = "user_id")
    public int getUserId() {
        return this.userId;
    }
    public void setUserId(int userId) {
        this.userId = userId;
    }
    private int userId;

    @Column(name = "project_id")
    public int getProjectId() {
        return this.projectId;
    }
    public void setProjectId(int projectId) {
        this.projectId = projectId;
    }
    private int projectId;
    
    @Version
    @Column(name = "data_version")
    public int getVersion() {
        return this.version;
    }
    public void setVersion(int version) {
        this.version = version;
    }
    private int version;

    public ProjectWriter() {

    }
}
