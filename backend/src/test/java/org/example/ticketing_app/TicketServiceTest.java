package org.example.ticketing_app;

import org.example.ticketing_app.entity.*;
import org.example.ticketing_app.mapper.*;
import org.example.ticketing_app.service.impl.TicketAssignmentServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;
import java.util.List;

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
    @Autowired
    private OrganizationMapper organizationMapper;
    @Autowired
    private TeamMapper teamMapper;
    @Autowired
    private TeamMemberMapper teamMemberMapper;

    @BeforeEach
    void setUp() {

        // Users

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

        // Organizations

        Organization organization1 = new Organization();
        organization1.setIdOrganization(1);
        organization1.setName("Engineering");

        Organization organization2 = new Organization();
        organization2.setIdOrganization(2);
        organization2.setName("Operations");

        organizationMapper.insertOrUpdate(organization1);
        organizationMapper.insertOrUpdate(organization2);

        // Teams

        Team team1 = new Team();
        team1.setIdTeam(1);
        team1.setOrganizationId(1);
        team1.setName("Backend Team");

        Team team2 = new Team();
        team2.setIdTeam(2);
        team2.setOrganizationId(1);
        team2.setName("Frontend Team");

        Team team3 = new Team();
        team3.setIdTeam(3);
        team3.setOrganizationId(2);
        team3.setName("Field Support Team");

        teamMapper.insertOrUpdate(team1);
        teamMapper.insertOrUpdate(team2);
        teamMapper.insertOrUpdate(team3);

        // Team Members

        TeamMember teamMember1 = new TeamMember();
        teamMember1.setIdTeamMember(1);
        teamMember1.setTeamId(1);
        teamMember1.setOrganizationId(1);
        teamMember1.setUserId(1001);

        TeamMember teamMember2 = new TeamMember();
        teamMember2.setIdTeamMember(2);
        teamMember2.setTeamId(2);
        teamMember2.setOrganizationId(1);
        teamMember2.setUserId(1002);

        TeamMember teamMember3 = new TeamMember();
        teamMember3.setIdTeamMember(3);
        teamMember3.setTeamId(1);
        teamMember3.setOrganizationId(1);
        teamMember3.setUserId(1003);

        TeamMember teamMember4 = new TeamMember();
        teamMember4.setIdTeamMember(4);
        teamMember4.setTeamId(3);
        teamMember4.setOrganizationId(2);
        teamMember4.setUserId(2001);

        TeamMember teamMember5 = new TeamMember();
        teamMember5.setIdTeamMember(5);
        teamMember5.setTeamId(3);
        teamMember5.setOrganizationId(2);
        teamMember5.setUserId(2003);

        teamMemberMapper.insertOrUpdate(teamMember1);
        teamMemberMapper.insertOrUpdate(teamMember2);
        teamMemberMapper.insertOrUpdate(teamMember3);
        teamMemberMapper.insertOrUpdate(teamMember4);
        teamMemberMapper.insertOrUpdate(teamMember5);

        // Tickets

        Ticket ticket1 = new Ticket();
        ticket1.setIdTicket(1);
        ticket1.setPosterId(1001);
        ticket1.setTitle("Move office furniture");
        ticket1.setDescription("Need help moving desks and chairs to Level 3.");
        ticket1.setDatePosted(LocalDateTime.of(2026, 9, 15, 9, 0));
        ticket1.setLocation("Building A");
        ticket1.setPay(80);
        ticket1.setEmail("john@example.com");
        ticket1.setStatus(TicketStatus.OPEN.name());

        Ticket ticket2 = new Ticket();
        ticket2.setIdTicket(2);
        ticket2.setPosterId(1002);
        ticket2.setTitle("Laptop setup assistance");
        ticket2.setDescription("Configure a new company laptop.");
        ticket2.setDatePosted(LocalDateTime.of(2026, 9, 15, 14, 30));
        ticket2.setLocation("Remote");
        ticket2.setPay(50);
        ticket2.setEmail("alice@example.com");
        ticket2.setStatus(TicketStatus.IN_PROGRESS.name());

        Ticket ticket3 = new Ticket();
        ticket3.setIdTicket(3);
        ticket3.setPosterId(1003);
        ticket3.setTitle("Printer troubleshooting");
        ticket3.setDescription("Office printer is not connecting to the network.");
        ticket3.setDatePosted(LocalDateTime.of(2026, 9, 16, 8, 15));
        ticket3.setLocation("Building B");
        ticket3.setPay(30);
        ticket3.setEmail("bob@example.com");
        ticket3.setStatus(TicketStatus.CLOSED.name());

        Ticket ticket4 = new Ticket();
        ticket4.setIdTicket(4);
        ticket4.setPosterId(1001);
        ticket4.setTitle("Network cable installation");
        ticket4.setDescription("Install network cable in meeting room.");
        ticket4.setDatePosted(LocalDateTime.of(2026, 9, 14, 11, 0));
        ticket4.setLocation("Building C");
        ticket4.setPay(40);
        ticket4.setEmail("john@example.com");
        ticket4.setStatus(TicketStatus.CLOSED.name());

        Ticket ticket5 = new Ticket();
        ticket5.setIdTicket(5);
        ticket5.setPosterId(1002);
        ticket5.setTitle("Projector repair");
        ticket5.setDescription("Projector is flickering.");
        ticket5.setDatePosted(LocalDateTime.of(2026, 9, 17, 10, 30));
        ticket5.setLocation("Building D");
        ticket5.setPay(60);
        ticket5.setEmail("alice@example.com");
        ticket5.setStatus(TicketStatus.OPEN.name());

        Ticket ticket6 = new Ticket();
        ticket6.setIdTicket(6);
        ticket6.setPosterId(1003);
        ticket6.setTitle("Software installation");
        ticket6.setDescription("Install licensed software.");
        ticket6.setDatePosted(LocalDateTime.of(2026, 9, 13, 16, 0));
        ticket6.setLocation("Building E");
        ticket6.setPay(70);
        ticket6.setEmail("bob@example.com");
        ticket6.setStatus(TicketStatus.IN_PROGRESS.name());

        ticketMapper.insertOrUpdate(ticket1);
        ticketMapper.insertOrUpdate(ticket2);
        ticketMapper.insertOrUpdate(ticket3);
        ticketMapper.insertOrUpdate(ticket4);
        ticketMapper.insertOrUpdate(ticket5);
        ticketMapper.insertOrUpdate(ticket6);

        // Ticket Assignments

// Ticket 1 individually assigned to David
        TicketAssignment assignment1 = new TicketAssignment();
        assignment1.setIdTicketAssignment(1);
        assignment1.setAssigneeId(2001);
        assignment1.setTicketId(1);
        assignment1.setDateAssigned(LocalDateTime.of(2026, 9, 15, 10, 0));
        assignment1.setRelatedTeamId(null);

// Ticket 2 assigned to Team 3 (David + Emma)
        TicketAssignment assignment2 = new TicketAssignment();
        assignment2.setIdTicketAssignment(2);
        assignment2.setAssigneeId(2001);
        assignment2.setTicketId(2);
        assignment2.setDateAssigned(LocalDateTime.of(2026, 9, 15, 15, 0));
        assignment2.setRelatedTeamId(3);

        TicketAssignment assignment3 = new TicketAssignment();
        assignment3.setIdTicketAssignment(3);
        assignment3.setAssigneeId(2003);
        assignment3.setTicketId(2);
        assignment3.setDateAssigned(LocalDateTime.of(2026, 9, 15, 15, 0));
        assignment3.setRelatedTeamId(3);

// Ticket 3 individually assigned to Emma
        TicketAssignment assignment4 = new TicketAssignment();
        assignment4.setIdTicketAssignment(4);
        assignment4.setAssigneeId(2003);
        assignment4.setTicketId(3);
        assignment4.setDateAssigned(LocalDateTime.of(2026, 9, 16, 9, 0));
        assignment4.setRelatedTeamId(null);

// Ticket 4 assigned to Team 1 (John + Bob)
        TicketAssignment assignment5 = new TicketAssignment();
        assignment5.setIdTicketAssignment(5);
        assignment5.setAssigneeId(1001);
        assignment5.setTicketId(4);
        assignment5.setDateAssigned(LocalDateTime.of(2026, 9, 14, 12, 0));
        assignment5.setRelatedTeamId(1);

        TicketAssignment assignment6 = new TicketAssignment();
        assignment6.setIdTicketAssignment(6);
        assignment6.setAssigneeId(1003);
        assignment6.setTicketId(4);
        assignment6.setDateAssigned(LocalDateTime.of(2026, 9, 14, 12, 0));
        assignment6.setRelatedTeamId(1);

// Ticket 5 individually assigned to David
        TicketAssignment assignment7 = new TicketAssignment();
        assignment7.setIdTicketAssignment(7);
        assignment7.setAssigneeId(2001);
        assignment7.setTicketId(5);
        assignment7.setDateAssigned(LocalDateTime.of(2026, 9, 17, 11, 0));
        assignment7.setRelatedTeamId(null);

// Ticket 6 individually assigned to Emma
        TicketAssignment assignment8 = new TicketAssignment();
        assignment8.setIdTicketAssignment(8);
        assignment8.setAssigneeId(2003);
        assignment8.setTicketId(6);
        assignment8.setDateAssigned(LocalDateTime.of(2026, 9, 13, 17, 0));
        assignment8.setRelatedTeamId(null);

        ticketAssignmentMapper.insertOrUpdate(assignment1);
        ticketAssignmentMapper.insertOrUpdate(assignment2);
        ticketAssignmentMapper.insertOrUpdate(assignment3);
        ticketAssignmentMapper.insertOrUpdate(assignment4);
        ticketAssignmentMapper.insertOrUpdate(assignment5);
        ticketAssignmentMapper.insertOrUpdate(assignment6);
        ticketAssignmentMapper.insertOrUpdate(assignment7);
        ticketAssignmentMapper.insertOrUpdate(assignment8);
    }

    @Test
    void ticketAssignmentFilter() throws Exception {
        ticketAssignmentService.getTicketAssignment(2001, Filter.timeAscending);
        ticketAssignmentService.getTicketAssignmentKeyWord(2001, "Network");
        List<TicketAssignmentReturn> result =
                ticketAssignmentService.getTicketAssignmentRelatedTo(
                        2001,
                        3
                );
    }
}
