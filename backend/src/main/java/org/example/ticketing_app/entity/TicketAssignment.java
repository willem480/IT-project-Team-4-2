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
 * @since 2026-09-24
 */
@Getter
@Setter
@ToString
@TableName("ticket_assignment")
public class TicketAssignment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idTicketAssignment", type = IdType.AUTO)
    private Integer idTicketAssignment;

    private Integer assigneeId;

    private Integer ticketId;

    private LocalDateTime dateAssigned;

    private Integer relatedTeamId;
}
