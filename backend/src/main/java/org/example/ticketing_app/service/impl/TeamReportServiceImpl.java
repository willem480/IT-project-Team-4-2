package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.*;
import org.example.ticketing_app.entity.TeamReport;
import org.example.ticketing_app.mapper.*;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
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
public class TeamReportServiceImpl
        extends ServiceImpl<TeamReportMapper, TeamReport> {

    private final TeamMapper teamMapper;
    private final TeamMemberMapper teamMemberMapper;
    private final UserMapper userMapper;
    private final TicketMapper ticketMapper;
    private final TicketAssignmentMapper ticketAssignmentMapper;

    @Transactional
    public TeamReport generateReport(int teamId) {

        Team team = teamMapper.selectById(teamId);

        if (team == null) {
            throw new RuntimeException("Team not found");
        }

        List<TeamMember> teamMembers =
                teamMemberMapper.selectList(
                        new LambdaQueryWrapper<TeamMember>()
                                .eq(TeamMember::getTeamId, teamId)
                );

        int totalAssigned = 0;
        int completed = 0;
        int inProgress = 0;
        int revenue = 0;

        StringBuilder body = new StringBuilder();

        StringBuilder completedTickets = new StringBuilder();
        StringBuilder inProgressTickets = new StringBuilder();

        body.append("Team Report --- ")
                .append(team.getName())
                .append("\n");

        body.append("Generated: ")
                .append(LocalDateTime.now())
                .append("\n\n");

        body.append("Members\n");
        body.append("-------\n");

        for (TeamMember teamMember : teamMembers) {

            User user =
                    userMapper.selectById(
                            teamMember.getUserId());

            body.append("- ")
                    .append(user.getName())
                    .append("\n");
        }

        body.append("\n");

        for (TeamMember teamMember : teamMembers) {

            User user =
                    userMapper.selectById(
                            teamMember.getUserId());

            List<TicketAssignment> assignments =
                    ticketAssignmentMapper.selectList(
                            new LambdaQueryWrapper<TicketAssignment>()
                                    .eq(
                                            TicketAssignment::getAssigneeId,
                                            teamMember.getUserId())
                    );

            totalAssigned += assignments.size();

            for (TicketAssignment assignment : assignments) {

                Ticket ticket =
                        ticketMapper.selectById(
                                assignment.getTicketId());

                if (ticket == null) {
                    continue;
                }

                TicketStatus status =
                        TicketStatus.valueOf(
                                ticket.getStatus());

                StringBuilder targetSection;

                if (status == TicketStatus.CLOSED) {

                    completed++;
                    revenue += ticket.getPay();

                    targetSection = completedTickets;

                } else if (status == TicketStatus.IN_PROGRESS) {

                    inProgress++;

                    targetSection = inProgressTickets;

                } else {
                    continue;
                }

                targetSection.append("Member: ")
                        .append(user.getName())
                        .append("\n");

                targetSection.append("Title: ")
                        .append(ticket.getTitle())
                        .append("\n");

                targetSection.append("Location: ")
                        .append(ticket.getLocation())
                        .append("\n");

                targetSection.append("Pay: $")
                        .append(ticket.getPay())
                        .append("\n");

                targetSection.append("Assigned: ")
                        .append(assignment.getDateAssigned())
                        .append("\n");

                if (ticket.getDateCompleted() != null) {

                    Duration duration =
                            Duration.between(
                                    assignment.getDateAssigned(),
                                    ticket.getDateCompleted());

                    long days = duration.toDays();
                    long hours = duration.toHours() % 24;

                    targetSection.append("Completed: ")
                            .append(ticket.getDateCompleted())
                            .append("\n");

                    targetSection.append("Time to complete: ")
                            .append(days)
                            .append(" days ")
                            .append(hours)
                            .append(" hours\n");
                }

                targetSection.append("\n");
            }
        }

        body.append("Statistics\n");
        body.append("----------\n");
        body.append("Total assigned jobs: ")
                .append(totalAssigned)
                .append("\n");

        body.append("Completed jobs: ")
                .append(completed)
                .append("\n");

        body.append("Jobs in progress: ")
                .append(inProgress)
                .append("\n");

        body.append("Revenue earned: $")
                .append(revenue)
                .append("\n\n");

        body.append("Completed Tickets\n");
        body.append("-----------------\n");

        if (completedTickets.isEmpty()) {
            body.append("None\n\n");
        } else {
            body.append(completedTickets)
                    .append("\n");
        }

        body.append("In Progress Tickets\n");
        body.append("-------------------\n");

        if (inProgressTickets.isEmpty()) {
            body.append("None\n");
        } else {
            body.append(inProgressTickets);
        }

        TeamReport report = new TeamReport();

        report.setTeamId(teamId);

        report.setTitle(
                "Team Performance Report - "
                        + team.getName());

        report.setBody(body.toString());

        report.setDateGenerated(
                LocalDateTime.now());

        save(report);

        return report;
    }
}
