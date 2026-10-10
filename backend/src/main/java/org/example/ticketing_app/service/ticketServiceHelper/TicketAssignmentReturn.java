package org.example.ticketing_app.service.ticketServiceHelper;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.time.LocalDateTime;

@Getter
@Setter
@ToString
public class TicketAssignmentReturn {

    private Integer posterID;

    private String posterName;

    private Integer assigneeID;

    private String assigneeName;

    private Integer organizationID;
    private String organizationName;
    private Integer teamID;
    private String teamName;
    private Integer idTicket;
    private String title;

    private String description;

    private LocalDateTime datePosted;

    private LocalDateTime dateAssigned;

    private LocalDateTime dateCompleted;

    private String location;

    private Integer pay;

    private String email;

    private String status;
}
