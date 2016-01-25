package kz.testcenter.updates.db.entities;

import kz.testcenter.updates.db.entities.users.User;

import javax.persistence.*;
import java.util.List;

@Entity
@Table(name = "projects", schema = "public")
public class Project {
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public int getId(){
        return this.id;
    }
    public void setId(int id) {
        this.id = id;
    }
    private int id;

    @Column(name = "project_name")
    public String getProjectName(){
        return this.projectName;
    }
    public void setProjectName(String projectName) {
        this.projectName = projectName;
    }
    private String projectName;

    @Column(name = "description")
    public String getDescription() {
        return this.description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    private String description;

    @OneToMany(cascade = CascadeType.ALL)
    @JoinColumn(name = "project_id")
    public List<Update> getUpdates() {
        return this.updates;
    }
    public void setUpdates(List<Update> updates) {
        this.updates = updates;
    }
    private List<Update> updates;

    @ManyToMany(mappedBy = "writeableProjects")
    public List<User> getWriters() {
        return this.writers;
    }
    public void setWriters(List<User> writers) {
        this.writers = writers;
    }
    private List<User> writers;

    @Version
    @Column(name = "data_version")
    public int getVersion() {
        return this.version;
    }
    public void setVersion(int version) {
        this.version = version;
    }
    private int version;

    public Project(){

    }
}
