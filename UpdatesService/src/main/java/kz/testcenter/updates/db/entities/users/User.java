package kz.testcenter.updates.db.entities.users;

import kz.testcenter.updates.db.entities.Project;
import kz.testcenter.updates.db.entities.Update;

import javax.persistence.*;
import java.util.List;

@Entity
@Table(name = "users", schema = "public")
public class User extends AbstractUser{
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public int getId() {
        return this.id;
    }
    public void setId(int id) {
        this.id = id;
    }
    private int id;

    @Column(name = "user_display_name")
    public String getUserDislayName() {
        return this.userDislayName;
    }
    public void setUserDislayName(String userDislayName) {
        this.userDislayName = userDislayName;
    }
    private String userDislayName;

    @Column(name = "role_name")
    public String getRoleName() {
        return this.roleName;
    }
    public void setRoleName(String roleName) {
        this.roleName= roleName;
    }
    private String roleName;

    @Column(name = "user_name")
    public String getUserName() {
        return super.getUserName();
    }
    public void setUserName(String userName) {
        super.setUserName(userName);
    }

    @Column(name = "password")
    protected String getPassword() {
        return super.getPassWord();
    }
    public void setPassword(String password) {
        super.setPassWord(password);
    }

    @Version
    @Column(name = "data_version")
    public int getVersion() {
        return this.version;
    }
    public void setVersion(int version) {
        this.version = version;
    }
    private int version;

    @ManyToMany
    @JoinTable(
            name = "project_writers",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "project_id")
    )
    public List<Project> getWriteableProjects() {
        return this.writeableProjects;
    }
    public void setWriteableProjects(List<Project> writeableProjects) {
        this.writeableProjects = writeableProjects;
    }
    private List<Project> writeableProjects;

    @ManyToMany
    @JoinTable(
            name = "update_writers",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "update_id")
    )
    public List<Update> getWriteableUpdates() {
        return this.writeableUpdates;
    }
    public void setWriteableUpdates(List<Update> writeableUpdates) {
        this.writeableUpdates = writeableUpdates;
    }
    private List<Update> writeableUpdates;

    @Override
    @Transient
    public UserType getUserType() {
        if (this.roleName != null && this.roleName.equals("admin"))
            return UserType.ADMIN;
        else
            return super.getUserType();
    }

    public User(){
        super(UserType.USER);
        this.setRoleName("user");
    }
}
