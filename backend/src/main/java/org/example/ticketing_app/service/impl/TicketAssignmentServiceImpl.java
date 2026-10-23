package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.example.ticketing_app.entity.*;
import org.example.ticketing_app.mapper.*;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.TicketNotificationService;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
@RequiredArgsConstructor
public class TicketAssignmentServiceImpl extends ServiceImpl<TicketAssignmentMapper, TicketAssignment> {
    private final TicketMapper ticketMapper;
    private final UserMapper userMapper;
    private final OrganizationMapper organizationMapper;
    private final TeamMapper teamMapper;
    private final TeamMemberMapper teamMemberMapper;
    private final TicketAssignmentMapper ticketAssignmentMapper;
    private final TicketNotificationService ticketNotificationService;

    public List<TicketAssignmentReturn> getTicketAssignment(Integer assigneeID, Filter filter) {
        List<TicketAssignment> ticketAssignments = getAssignmentHelper(assigneeID);
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        setTicketAssignmentReturn(ticketAssignments, ticketAssignmentReturns);

        switch (filter){
            case timeAscending -> {
                return ticketAssignmentReturns.stream().sorted(Comparator.comparing(TicketAssignmentReturn::getDateAssigned)).toList();
            }
            case timeDescending -> {
                return ticketAssignmentReturns.stream().sorted(Comparator.comparing(TicketAssignmentReturn::getDateAssigned).reversed()).toList();
            }
            case payAscending -> {
                return ticketAssignmentReturns.stream().sorted(Comparator.comparing(TicketAssignmentReturn::getPay)).toList();
            }
            case payDescending -> {
                return ticketAssignmentReturns.stream().sorted(Comparator.comparing(TicketAssignmentReturn::getPay).reversed()).toList();
            }
            case statusAscending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(
                                t -> switch (TicketStatus.valueOf(t.getStatus())) {
                                    case OPEN -> 0;
                                    case IN_PROGRESS -> 1;
                                    case CLOSED -> 2;
                                    case CANCELLED -> 3;
                                }))
                        .toList();
            }
            case statusDescending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(
                                t -> switch (TicketStatus.valueOf(t.getStatus())) {
                                    case CLOSED -> 0;
                                    case IN_PROGRESS -> 1;
                                    case OPEN -> 2;
                                    case CANCELLED -> 3;
                                }))
                        .toList();
            }
        }

        return ticketAssignmentReturns;
    }

    public List<TicketAssignmentReturn> getTicketAssignment(Integer assigneeID) {
        List<TicketAssignment> ticketAssignments = getAssignmentHelper(assigneeID);
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        setTicketAssignmentReturn(ticketAssignments, ticketAssignmentReturns);
        return ticketAssignmentReturns;
    }

    public List<TicketAssignmentReturn> getCompletedTickets(Integer assigneeID, Filter filter) {
        List<TicketAssignment> ticketAssignments = lambdaQuery()
                .eq(TicketAssignment::getAssigneeId, assigneeID)
                .list()
                .stream()
                .filter(ta -> {
                    Ticket ticket = ticketMapper.selectById(ta.getTicketId());
                    return TicketStatus.CLOSED.name().equals(ticket.getStatus());
                })
                .toList();
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        setTicketAssignmentReturn(ticketAssignments, ticketAssignmentReturns);
        if (filter == null){
            return ticketAssignmentReturns;
        }
        switch (filter) {
            case timeAscending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(TicketAssignmentReturn::getDateCompleted))
                        .toList();
            }

            case timeDescending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(TicketAssignmentReturn::getDateCompleted).reversed())
                        .toList();
            }

            case payAscending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(TicketAssignmentReturn::getPay))
                        .toList();
            }

            case payDescending -> {
                return ticketAssignmentReturns.stream()
                        .sorted(Comparator.comparing(TicketAssignmentReturn :: getPay).reversed())
                        .toList();
            }

            default -> {
                return ticketAssignmentReturns;
            }
        }
    }

    private List<TicketAssignment> getAssignmentHelper(Integer assigneeID) {
        return lambdaQuery()
                .eq(TicketAssignment::getAssigneeId, assigneeID)
                .list()
                .stream()
                .filter(ta -> {
                    Ticket ticket = ticketMapper.selectById(ta.getTicketId());
                    return TicketStatus.IN_PROGRESS.name().equals(ticket.getStatus()) || TicketStatus.CLOSED.name().equals(ticket.getStatus());
                })
                .toList();
    }

    public List<TicketAssignmentReturn> getTicketAssignmentKeyWord(
            Integer assigneeID,
            String keyword) {

        List<TicketAssignment> ticketAssignments = getAssignmentHelper(assigneeID);
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        setTicketAssignmentReturn(ticketAssignments, ticketAssignmentReturns);

        JaroWinklerSimilarity similarity = new JaroWinklerSimilarity();

        String search = keyword.toLowerCase();

        return ticketAssignmentReturns.stream()
                .sorted(
                        Comparator
                                .comparingInt((TicketAssignmentReturn t) -> {
                                    String title = t.getTitle().toLowerCase();
                                    String description = t.getDescription().toLowerCase();

                                    if (title.equals(search)) {
                                        return 0;
                                    }

                                    if (title.contains(search)) {
                                        return 1;
                                    }

                                    if (description.contains(search)) {
                                        return 2;
                                    }

                                    return 3;
                                })
                                .thenComparingDouble(t -> {
                                    double titleScore = similarity.apply(
                                            search,
                                            t.getTitle().toLowerCase());

                                    double descriptionScore = similarity.apply(
                                            search,
                                            t.getDescription().toLowerCase());

                                    return -Math.max(titleScore, descriptionScore);
                                }))
                .toList();
    }

    public List<TicketAssignmentReturn> getTicketAssignmentRelatedTo(Integer assigneeID, Integer teamID) {
        List<TicketAssignment> ticketAssignments =
                getAssignmentHelper(assigneeID)
                        .stream()
                        .filter(ticketAssignment -> Objects.equals(ticketAssignment.getRelatedTeamId(), teamID)).toList();
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        setTicketAssignmentReturn(ticketAssignments, ticketAssignmentReturns);
        return ticketAssignmentReturns;
    }

    private void setTicketAssignmentReturn(List<TicketAssignment> ticketAssignments, List<TicketAssignmentReturn> ticketAssignmentReturns) {
        for (TicketAssignment ticketAssignment : ticketAssignments) {
            TicketAssignmentReturn ticketAssignmentReturn = new TicketAssignmentReturn();
            Ticket ticket = ticketMapper.selectById(ticketAssignment.getTicketId());
            User assignee = userMapper.selectById(ticketAssignment.getAssigneeId());
            User poster = userMapper.selectById(ticket.getPosterId());

            Integer teamID = ticketAssignment.getRelatedTeamId();
            if (teamID != null) {
                Team team = teamMapper.selectById(teamID);
                Organization organization = organizationMapper.selectById(team.getOrganizationId());
                ticketAssignmentReturn.setOrganizationID(organization.getIdOrganization());
                ticketAssignmentReturn.setTeamID(team.getIdTeam());
                ticketAssignmentReturn.setTeamName(team.getName());
                ticketAssignmentReturn.setOrganizationName(organization.getName());
            }

            ticketAssignmentReturn.setPosterID(poster.getIdUser());
            ticketAssignmentReturn.setPosterName(poster.getName());
            ticketAssignmentReturn.setAssigneeID(assignee.getIdUser());
            ticketAssignmentReturn.setAssigneeName(assignee.getName());
            ticketAssignmentReturn.setIdTicket(ticket.getIdTicket());
            ticketAssignmentReturn.setTitle(ticket.getTitle());
            ticketAssignmentReturn.setDescription(ticket.getDescription());
            ticketAssignmentReturn.setDatePosted(ticket.getDatePosted());
            ticketAssignmentReturn.setDateAssigned(ticketAssignment.getDateAssigned());
            ticketAssignmentReturn.setPay(ticket.getPay());
            ticketAssignmentReturn.setEmail(ticket.getEmail());
            ticketAssignmentReturn.setLocation(ticket.getLocation());
            ticketAssignmentReturn.setStatus(ticket.getStatus());
            ticketAssignmentReturn.setDateCompleted(ticket.getDateCompleted());
            ticketAssignmentReturns.add(ticketAssignmentReturn);
        }
    }

    @Transactional
    public void delegateJobIndividual(Integer ticketID, Integer assigneeID, Integer teamId) {
        List<TicketAssignment> ticketAssignments = lambdaQuery().eq(TicketAssignment::getTicketId, ticketID).eq(TicketAssignment::getAssigneeId, assigneeID).list();
        if (ticketAssignments.isEmpty()) {
            TicketAssignment ticketAssignment = new TicketAssignment();
            ticketAssignment.setTicketId(ticketID);
            ticketAssignment.setAssigneeId(assigneeID);
            ticketAssignment.setRelatedTeamId(teamId);
            ticketAssignment.setDateAssigned(LocalDateTime.now());
            Ticket ticket = ticketMapper.selectById(ticketID);
            ticket.setStatus(TicketStatus.IN_PROGRESS.name());
            ticketMapper.insertOrUpdate(ticket);
            save(ticketAssignment);

            User poster = userMapper.selectById(ticket.getPosterId());
            if (poster != null && poster.getSubscribeEmail() == 1){
                User assignee = userMapper.selectById(assigneeID);
                String assigneeName = assignee != null && assignee.getName() != null
                        ? assignee.getName()
                        : "User " + assigneeID;
                ticketNotificationService.sendAssignedNotification(ticket, poster, assigneeName);
            }
        }
        else{
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    String.format("Ticket with id: %d is already assigned to user with id: %d", ticketID, assigneeID));
        }
    }

    @Transactional
    public void delegationJobTeam(Integer ticketID, Integer teamID) {
        Team team = teamMapper.selectById(teamID);
        List<TeamMember> teamMembers = teamMemberMapper.selectList(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getTeamId, teamID)
        );

        for(TeamMember teamMember : teamMembers ){
            Integer assigneeID = teamMember.getUserId();
            List<TicketAssignment> ticketAssignments = lambdaQuery().eq(TicketAssignment::getTicketId, ticketID).eq(TicketAssignment::getAssigneeId, assigneeID).list();
            if (ticketAssignments.isEmpty()) {
                TicketAssignment ticketAssignment = new TicketAssignment();
                ticketAssignment.setTicketId(ticketID);
                ticketAssignment.setAssigneeId(assigneeID);
                ticketAssignment.setRelatedTeamId(teamID);
                ticketAssignment.setDateAssigned(LocalDateTime.now());
                Ticket ticket = ticketMapper.selectById(ticketID);
                ticket.setStatus(TicketStatus.IN_PROGRESS.name());
                ticketMapper.insertOrUpdate(ticket);
                save(ticketAssignment);
            }
            else{
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        String.format("Ticket with id: %d is already assigned to user with id: %d", ticketID, assigneeID));
            }

        }

        Ticket ticket = ticketMapper.selectById(ticketID);
        User poster = userMapper.selectById(ticket.getPosterId());

        if (poster != null
                && Byte.valueOf((byte) 1).equals(poster.getSubscribeEmail())) {

            // Team name
            String teamName =
                    team != null && team.getName() != null
                            ? team.getName()
                            : "Team " + teamID;

            // Organisation name
            String organizationName = "Unknown Organisation";

            if (team != null && team.getOrganizationId() != null) {

                Organization organization =
                        organizationMapper.selectById(
                                team.getOrganizationId()
                        );

                if (organization != null
                        && organization.getName() != null) {

                    organizationName =
                            organization.getName();
                }
            }

            // Team member names
            List<String> memberNamesList =
                    new ArrayList<>();

            for (TeamMember teamMember : teamMembers) {

                User member =
                        userMapper.selectById(
                                teamMember.getUserId()
                        );

                if (member != null
                        && member.getName() != null) {

                    memberNamesList.add(
                            member.getName()
                    );
                }
            }

            String memberNames;

            if (memberNamesList.isEmpty()) {
                memberNames = "No members";
            } else {
                memberNames =
                        String.join(
                                ", ",
                                memberNamesList
                        );
            }

            ticketNotificationService
                    .sendTeamAssignedNotification(
                            ticket,
                            poster,
                            teamName,
                            organizationName,
                            memberNames
                    );
        }
    }

    @Transactional
    public void deallocateJob(int ticketId, int operatorId){
        TicketAssignment ticketAssignment = lambdaQuery().eq(TicketAssignment::getTicketId, ticketId).eq(TicketAssignment::getAssigneeId, operatorId).one();
        if (ticketAssignment == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "no ticket assignment found for this ticketId " + ticketId + " and operatorId " + operatorId);
        }
        Ticket ticket = ticketMapper.selectById(ticketId);
        if (ticket == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "no ticket found for this ticketId " + ticketId);
        }

        ticketAssignmentMapper.deleteById(ticketAssignment.getIdTicketAssignment());

        if (Objects.equals(ticket.getStatus(), TicketStatus.CLOSED.name())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "you cannot deallocate a closed ticket");
        }
        else if (Objects.equals(ticket.getStatus(), TicketStatus.IN_PROGRESS.name())) {
            List<TicketAssignment> ticketAssignments = lambdaQuery().eq(TicketAssignment::getTicketId, ticketId).list();
            if (ticketAssignments.isEmpty()) {
                ticket.setStatus(TicketStatus.OPEN.name());
                ticketMapper.insertOrUpdate(ticket);
            }

            User poster = userMapper.selectById(ticket.getPosterId());
            if (poster != null && poster.getSubscribeEmail() == 1){
                ticketNotificationService.sendDeallocatedNotification(ticket, poster);
            }
        }

    }
}
