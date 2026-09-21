package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.apache.commons.text.similarity.LevenshteinDistance;
import org.example.ticketing_app.entity.*;
import org.example.ticketing_app.mapper.*;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
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

    private List<TicketAssignment> getAssignmentHelper(Integer assigneeID) {
        return lambdaQuery()
                .eq(TicketAssignment::getAssigneeId, assigneeID)
                .list()
                .stream()
                .filter(ta -> {
                    Ticket ticket = ticketMapper.selectById(ta.getTicketId());
                    return TicketStatus.OPEN.name().equals(ticket.getStatus())
                            || TicketStatus.IN_PROGRESS.name().equals(ticket.getStatus());
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
        List<TicketAssignment> ticketAssignments = lambdaQuery()
                .eq(TicketAssignment::getAssigneeId, assigneeID).eq(TicketAssignment::getRelatedTeamId, teamID)
                .list()
                .stream()
                .filter(ta -> {
                    Ticket ticket = ticketMapper.selectById(ta.getTicketId());
                    return TicketStatus.OPEN.name().equals(ticket.getStatus())
                            || TicketStatus.IN_PROGRESS.name().equals(ticket.getStatus());
                })
                .toList();
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
            ticketAssignmentReturn.setTitle(ticket.getTitle());
            ticketAssignmentReturn.setDescription(ticket.getDescription());
            ticketAssignmentReturn.setDatePosted(ticket.getDatePosted());
            ticketAssignmentReturn.setDateAssigned(ticketAssignment.getDateAssigned());
            ticketAssignmentReturn.setPay(ticket.getPay());
            ticketAssignmentReturn.setEmail(ticket.getEmail());
            ticketAssignmentReturn.setLocation(ticket.getLocation());
            ticketAssignmentReturn.setStatus(ticket.getStatus());
            ticketAssignmentReturns.add(ticketAssignmentReturn);
        }
    }
}
