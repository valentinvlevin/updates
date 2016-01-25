package kz.testcenter.updates.services.datatypes;

import javax.xml.bind.annotation.*;

@XmlRootElement(name = "project")
@XmlAccessorType(XmlAccessType.PROPERTY)
@XmlType(propOrder = {
        "id",
        "projectName",
        "description"
})
public class dtProject {
    @XmlElement(name = "id")
    public long getId() {
        return id;
    }
    public void setId(long id) {
        this.id = id;
    }
    private long id;

    @XmlElement(name = "projectName")
    public String getProjectName() {
        return projectName;
    }
    public void setProjectName(String projectName) {
        this.projectName = projectName;
    }
    private String projectName;

    @XmlAttribute(name = "description")
    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }
    private String description;
}
