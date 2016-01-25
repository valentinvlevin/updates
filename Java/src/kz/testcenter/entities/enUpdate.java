package kz.testcenter.entities;

import javax.persistence.*;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlElement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "\"Updates\"", schema = "public", catalog = "\"Updates\"")
@XmlAccessorType(XmlAccessType.NONE)
@XmlRootElement(name="update")
public class enUpdate {

    @Id
    @Column(name = "\"ID\"", nullable = false, insertable = false, updatable = false)
    @XmlAttribute(name="id")
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    private int id;

    @Basic
    @Column(name = "\"IDProject\"", nullable = false, insertable = true, updatable = true)
    public int getIdProject() {
      return idProject;
    }
    public void setIdProject(int idProject) {
        this.idProject = idProject;
    }
    private int idProject;

    @Basic
    @Column(name = "\"FilePath\"", nullable = false, insertable = true, updatable = true, length = 100)
    public String getFilePath() {
        return filePath;
    }
    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }
    private String filePath;

    @Basic
    @Column(name = "\"FileName\"", nullable = false, insertable = true, updatable = true, length = 100)
    @XmlAttribute(name="fileName")
    public String getFileName() {
        return fileName;
    }
    public void setFileName(String fileName) {
        this.fileName = fileName;
    }
    private String fileName;

    @Basic
    @Column(name = "\"FileSize\"", nullable = false, insertable = true, updatable = true)
    @XmlAttribute(name="fileSize")
    public int getFileSize() {
        return fileSize;
    }
    public void setFileSize(int fileSize) {
        this.fileSize = fileSize;
    }
    private int fileSize;

    @Basic
    @Column(name = "\"Desc\"", nullable = false, insertable = true, updatable = true, length = 200)
    @XmlElement(name="desc")
    public String getDesc() {
        return desc;
    }
    public void setDesc(String desc) {
        this.desc = desc;
    }
    private String desc;

    @Basic
    @Column(name = "\"Ord\"", nullable = false, insertable = true, updatable = true)
    @XmlElement(name="ord")
    public short getOrd() {
        return ord;
    }
    public void setOrd(short ord) {
        this.ord = ord;
    }
    private short ord;

    @Basic
    @Column(name = "\"UpdateDBVersionTo\"", nullable = false, insertable = true, updatable = true)
    @XmlElement(name="updateDBVersionTo")
    public short getUpdateDBVersionTo() {
        return this.updateDBVersionTo;
    }
    public void setUpdateDBVersionTo(short updateDBVersionTo) {
        this.updateDBVersionTo = updateDBVersionTo;
    }
    private short updateDBVersionTo;

    @Basic
    @Column(name = "\"UpdateAppVersionTo\"", nullable = false, insertable = true, updatable = true)
    @XmlElement(name="updateAppVersionTo")
    public short getUpdateAppVersionTo() {
        return this.updateAppVersionTo;
    }
    public void setUpdateAppVersionTo(short updateAppVersionTo) {
        this.updateAppVersionTo = updateAppVersionTo;
    }
    private short updateAppVersionTo;

    @Basic
    @Column(name = "\"AddDateTime\"", nullable = false, insertable = true, updatable = true)
    @XmlElement(name="addDateTime")
    public Timestamp getAddDateTime() {
        return addDateTime;
    }
    public void setAddDateTime(Timestamp addDateTime) {
        this.addDateTime = addDateTime;
    }
    private Timestamp addDateTime;

    @OneToMany(fetch = FetchType.LAZY)
    @JoinColumn(name = "idUpdate")
    public List<enUpdateReceiver> getUpdateReceivers()
    {
      return this.updateReceivers;
    }
    public void setUpdateReceivers(List<enUpdateReceiver> updateReceivers)
    {
      this.updateReceivers = updateReceivers;
    }
    private List<enUpdateReceiver> updateReceivers = new ArrayList<enUpdateReceiver>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        enUpdate enUpdate = (enUpdate) o;

        if (fileSize != enUpdate.fileSize) return false;
        if (id != enUpdate.id) return false;
        if (idProject != enUpdate.idProject) return false;
        if (ord != enUpdate.ord) return false;
        if (addDateTime != null ? !addDateTime.equals(enUpdate.addDateTime) : enUpdate.addDateTime != null)
            return false;
        if (desc != null ? !desc.equals(enUpdate.desc) : enUpdate.desc != null) return false;
        if (fileName != null ? !fileName.equals(enUpdate.fileName) : enUpdate.fileName != null) return false;

        return true;
    }

    @Override
    public int hashCode() {
        int result = id;
        result = 31 * result + idProject;
        result = 31 * result + (fileName != null ? fileName.hashCode() : 0);
        result = 31 * result + fileSize;
        result = 31 * result + (desc != null ? desc.hashCode() : 0);
        result = 31 * result + (int) ord;
        result = 31 * result + (addDateTime != null ? addDateTime.hashCode() : 0);
        return result;
    }
}
