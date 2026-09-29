package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.profileHelper.UserReturn;
import org.example.ticketing_app.service.impl.TicketAssignmentServiceImpl;
import org.example.ticketing_app.service.impl.TicketServiceImpl;
import org.example.ticketing_app.service.impl.UserServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/profilePage")
@RequiredArgsConstructor
public class ProfileController {
    private final TicketServiceImpl ticketService;
    private final TicketAssignmentServiceImpl ticketAssignmentService;
    private final UserServiceImpl userService;

    @PostMapping("getCompletedTickets")
    public List<TicketAssignmentReturn> getCompletedTickets(@RequestParam int userId, @RequestParam(required = false)Filter filter) {
        return ticketAssignmentService.getCompletedTickets(userId, filter);
    }

    @PostMapping("getPostedTickets")
    public List<Ticket> getPostedTickets(@RequestParam int userId, @RequestParam(required = false)Filter filter) {
        return ticketService.getPostedTickets(userId, filter);
    }

    @PostMapping("getUser")
    public UserReturn getUser(@RequestParam int userId) {
        return userService.getUserById(userId);
    }
}
