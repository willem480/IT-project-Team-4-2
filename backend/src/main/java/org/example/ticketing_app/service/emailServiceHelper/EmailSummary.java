package org.example.ticketing_app.service.emailServiceHelper;

import lombok.Getter;
import lombok.Setter;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.User;

import java.util.List;

@Getter
@Setter
public class EmailSummary {

    private User user;

    private List<Ticket> postedTickets;

    private int totalAssignedJobs;

    private int completedJobs;

    private int inProgressJobs;

    private int totalEarnings;
}