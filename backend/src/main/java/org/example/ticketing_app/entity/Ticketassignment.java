package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.TableId;
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
public class Ticketassignment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTicketAssignment")
    private Integer idTicketAssignment;

    private Integer userIduser;

    private Integer ticketIdticket;

    private LocalDateTime dateAssigned;
}
