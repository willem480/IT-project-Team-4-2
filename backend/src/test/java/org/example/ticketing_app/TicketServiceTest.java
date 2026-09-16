package org.example.ticketing_app;

import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.TicketAssignment;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.impl.TicketAssignmentServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;

@SpringBootTest
public class TicketServiceTest {
    @Autowired
    private TicketMapper ticketMapper;
    @Autowired
    private TicketAssignmentMapper ticketAssignmentMapper;
    @Autowired
    private TicketAssignmentServiceImpl ticketAssignmentService;
    @Autowired
    private UserMapper userMapper;
    @BeforeEach
    void setUp() {
        User user1 = new User();
        user1.setIdUser(1001);
        user1.setName("John Smith");
        user1.setEmail("john@example.com");

        User user2 = new User();
        user2.setIdUser(1002);
        user2.setName("Alice Lee");
        user2.setEmail("alice@example.com");

        User user3 = new User();
        user3.setIdUser(1003);
        user3.setName("Bob Wilson");
        user3.setEmail("bob@example.com");

        User user4 = new User();
        user4.setIdUser(2001);
        user4.setName("David Chen");
        user4.setEmail("david@example.com");

        User user5 = new User();
        user5.setIdUser(2003);
        user5.setName("Emma Brown");
        user5.setEmail("emma@example.com");

        userMapper.insertOrUpdate(user1);
        userMapper.insertOrUpdate(user2);
        userMapper.insertOrUpdate(user3);
        userMapper.insertOrUpdate(user4);
        userMapper.insertOrUpdate(user5);

        // Test data ticket
        Ticket ticket1 = new Ticket();
        ticket1.setIdTicket(1);
        ticket1.setPosterId(1001);
        ticket1.setTitle("Move office furniture");
        ticket1.setDescription("Need help moving desks and chairs to Level 3.");
        ticket1.setDatePosted(LocalDateTime.of(2026, 9, 15, 9, 0));
        ticket1.setLocation("Building A");
        ticket1.setPay(80);
        ticket1.setEmail("john@example.com");
        ticket1.setStatus("OPEN");

        Ticket ticket2 = new Ticket();
        ticket2.setIdTicket(2);
        ticket2.setPosterId(1002);
        ticket2.setTitle("Laptop setup assistance");
        ticket2.setDescription("Configure a new company laptop.");
        ticket2.setDatePosted(LocalDateTime.of(2026, 9, 15, 14, 30));
        ticket2.setLocation("Remote");
        ticket2.setPay(50);
        ticket2.setEmail("alice@example.com");
        ticket2.setStatus("ASSIGNED");

        Ticket ticket3 = new Ticket();
        ticket3.setIdTicket(3);
        ticket3.setPosterId(1003);
        ticket3.setTitle("Printer troubleshooting");
        ticket3.setDescription("Office printer is not connecting to the network.");
        ticket3.setDatePosted(LocalDateTime.of(2026, 9, 16, 8, 15));
        ticket3.setLocation("Building B");
        ticket3.setPay(30);
        ticket3.setEmail("bob@example.com");
        ticket3.setStatus("COMPLETED");
        ticketMapper.insertOrUpdate(ticket1);
        ticketMapper.insertOrUpdate(ticket2);
        ticketMapper.insertOrUpdate(ticket3);

        //Test data ticket assignment
        TicketAssignment assignment1 = new TicketAssignment();
        assignment1.setIdTicketAssignment(1);
        assignment1.setAssigneeId(2001);
        assignment1.setTicketId(1);
        assignment1.setDateAssigned(LocalDateTime.of(2026, 9, 15, 10, 0));

        TicketAssignment assignment2 = new TicketAssignment();
        assignment2.setIdTicketAssignment(2);
        assignment2.setAssigneeId(2001);
        assignment2.setTicketId(2);
        assignment2.setDateAssigned(LocalDateTime.of(2026, 9, 15, 15, 0));

        TicketAssignment assignment3 = new TicketAssignment();
        assignment3.setIdTicketAssignment(3);
        assignment3.setAssigneeId(2003);
        assignment3.setTicketId(3);
        assignment3.setDateAssigned(LocalDateTime.of(2026, 9, 16, 9, 0));
        ticketAssignmentMapper.insertOrUpdate(assignment1);
        ticketAssignmentMapper.insertOrUpdate(assignment2);
        ticketAssignmentMapper.insertOrUpdate(assignment3);
    }

    @Test
    void ticketAssignmentFilter() throws Exception {
        ticketAssignmentService.getTicketAssignmentByAssigneeID(2001);
    }
}
