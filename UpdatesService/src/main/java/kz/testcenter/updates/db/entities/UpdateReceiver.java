package kz.testcenter.updates.db.entities;

import javax.persistence.*;
import java.util.Date;

@Entity
@Table(name = "update_receive_log", schema = "public")
public class UpdateReceiver {
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

    @Column(name = "update_id")
    public int getUpdateId(){
        return this.updateId;
    }
    public void setUpdateId(int updateId) {
        this.updateId = updateId;
    }
    private int updateId;

    @Column(name = "receiver_id")
    public String getReceiverId() {
        return this.receiverId;
    }
    public void setReceiverId(String receiverId) {
        this.receiverId = receiverId;
    }
    private String receiverId;

    @Column(name = "receive_date_time")
    @Temporal(TemporalType.TIMESTAMP)
    public Date getReceiveDateTime() {
        return this.receiveDateTime;
    }
    public void setReceiveDateTime(Date receiveDateTime) {
        this.receiveDateTime = receiveDateTime;
    }
    private Date receiveDateTime;

    public UpdateReceiver() {

    }
}
