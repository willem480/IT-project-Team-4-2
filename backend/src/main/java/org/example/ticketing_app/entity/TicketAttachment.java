package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * 
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Getter
@Setter
@ToString
@TableName("ticket_attachment")
public class TicketAttachment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTicketAttachment")
    private Integer idTicketAttachment;

    private Integer ticketId;

    private String attachmentName;

    private byte[] attachmentContent;
}
