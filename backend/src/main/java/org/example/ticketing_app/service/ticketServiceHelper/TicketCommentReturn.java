package org.example.ticketing_app.service.ticketServiceHelper;
import lombok.Getter;
import lombok.Setter;


import java.time.LocalDateTime;
@Getter
@Setter
public class TicketCommentReturn {

    private Integer idticketComment;

    private Integer ticketId;

    private Integer posterId;

    private LocalDateTime date;

    private String content;

    private boolean ownedByCurUser = false;

     private String userName;
}
