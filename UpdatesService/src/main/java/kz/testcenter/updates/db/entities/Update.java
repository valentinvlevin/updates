package kz.testcenter.updates.db.entities;

import kz.testcenter.updates.db.entities.users.User;

import javax.persistence.*;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "updates", schema = "public")
public class Update {
    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public int getId(){
        return this.id;
    }
    public void setId(int id){
        this.id = id;
    }
    private int id;

    @Column(name = "project_id")
    public int getProjectId(){
        return this.projectId;
    }
    public void setProjectId(int projectId) {
        this.projectId = projectId;
    }
    private int projectId;

    @Column(name = "file_name")
    public String getFileName(){
        return this.fileName;
    }
    public void setFileName(String fileName) {
        this.fileName = fileName;
    }
    private String fileName;

    @Column(name = "file_size")
    public int getFileSize() {
        return this.fileSize;
    }
    public void setFileSize(int fileSize){
        this.fileSize = fileSize;
    }
    private int fileSize;

    @Column(name = "description")
    public String getDescription() {
        return this.description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    private String description;

    @Column(name = "ord")
    public short getOrd() {
        return this.ord;
    }
    public void setOrd(short ord) {
        this.ord = ord;
    }
    private short ord;

    @Column(name = "add_date_time")
    @Temporal(TemporalType.TIMESTAMP)
    public Date getAddDateTime() {
        return this.addDateTime;
    }
    public void setAddDateTime(Date addDateTime) {
        this.addDateTime = addDateTime;
    }
    private Date addDateTime;

    @ManyToMany(mappedBy = "writeableUpdates")
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

    public Update() {

    }
}
