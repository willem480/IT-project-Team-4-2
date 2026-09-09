package org.example.ticketing_app.entity;

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
 * @since 2026-09-09
 */
@Getter
@Setter
@ToString
@TableName("ticket_assignment")
public class TicketAssignment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTicketAssignment")
    private Integer idTicketAssignment;

    private Integer userId;

    private Integer ticketId;

    private LocalDateTime dateAssigned;
}
