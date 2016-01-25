package kz.testcenter.entities;

import javax.persistence.*;
import javax.persistence.Entity;
import javax.persistence.Table;
import javax.xml.bind.annotation.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "\"Projects\"", schema = "public", catalog = "\"Updates\"")
@XmlAccessorType(XmlAccessType.NONE)
@XmlRootElement(name="project")
public class enProject {
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
    @Column(name = "\"ProjectName\"", nullable = false, insertable = true, updatable = true, length = 50)
    public String getProjectName() {
        return projectName;
    }
    public void setProjectName(String projectName) {
        this.projectName = projectName;
    }
    @XmlElement(name="projectName")
    private String projectName;

    @Basic
    @Column(name = "\"Desc\"", nullable = false, insertable = true, updatable = true, length = 200)
    public String getDesc() {
        return desc;
    }
    public void setDesc(String desc) {
        this.desc = desc;
    }
    @XmlElement(name="desc")
    private String desc;

    @OneToMany(fetch = FetchType.LAZY)
    @JoinColumn(name = "idProject")
    @OrderBy("ord")
    public List<enUpdate> getUpdates()
    {
      return this.updates;
    }
    public void setUpdates(List<enUpdate> updates)
    {
      this.updates = updates;
    }
    private List<enUpdate> updates = new ArrayList<enUpdate>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        enProject enProject = (enProject) o;

        if (id != enProject.id) return false;
        if (desc != null ? !desc.equals(enProject.desc) : enProject.desc != null) return false;
        if (projectName != null ? !projectName.equals(enProject.projectName) : enProject.projectName != null)
            return false;

        return true;
    }

    @Override
    public int hashCode() {
        int result = id;
        result = 31 * result + (projectName != null ? projectName.hashCode() : 0);
        result = 31 * result + (desc != null ? desc.hashCode() : 0);
        return result;
    }
}
