package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * <p>
 * 
 * </p>
 *
 * @author Yucong
 * @since 2026-10-05
 */
@Getter
@Setter
@ToString
@TableName("ticket_comment")
public class TicketComment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idticket_comment", type = IdType.AUTO)
    private Integer idticketComment;

    private Integer ticketIdticket;

    private Integer userIduser;

    private LocalDateTime date;

    private String content;
}
