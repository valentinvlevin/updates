package kz.testcenter.entities;

import javax.persistence.*;
import java.sql.Timestamp;
import java.util.Date;

@Entity
@Table(name = "\"UpdateReceiveLog\"", schema = "public", catalog = "\"Updates\"")
public class enUpdateReceiver {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    private int id;

    @Basic
    @Column(name = "\"IDUpdate\"", nullable = false, insertable = true, updatable = true)
    public int getIdUpdate() {
        return idUpdate;
    }
    public void setIdUpdate(int idUpdate) {
        this.idUpdate = idUpdate;
    }
    private int idUpdate;

    @Basic
    @Column(name = "\"IDReceiver\"", nullable = false, insertable = true, updatable = true, length = 20)
    public String getIdReceiver() {
        return idReceiver;
    }
    public void setIdReceiver(String idReceiver) {
        this.idReceiver = idReceiver;
    }
    private String idReceiver;

    @Basic
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "\"ReceiveDateTime\"", nullable = false, insertable = false, updatable = false, columnDefinition = "timestamp default now()")
    public Date getReceiveDateTime() {
        return receiveDateTime;
    }
    public void setReceiveDateTime(Date receiveDateTime) {
        this.receiveDateTime = receiveDateTime;
    }
    private Date receiveDateTime;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        enUpdateReceiver that = (enUpdateReceiver) o;

        if (id != that.id) return false;
        if (idUpdate != that.idUpdate) return false;
        if (idReceiver != null ? !idReceiver.equals(that.idReceiver) : that.idReceiver != null) return false;
        if (receiveDateTime != null ? !receiveDateTime.equals(that.receiveDateTime) : that.receiveDateTime != null)
            return false;

        return true;
    }

    @Override
    public int hashCode() {
        int result = id;
        result = 31 * result + idUpdate;
        result = 31 * result + (idReceiver != null ? idReceiver.hashCode() : 0);
        result = 31 * result + (receiveDateTime != null ? receiveDateTime.hashCode() : 0);
        return result;
    }
}
