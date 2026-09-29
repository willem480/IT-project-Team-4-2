package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.*;
import org.example.ticketing_app.mapper.*;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import lombok.RequiredArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

import org.example.ticketing_app.entity.OrganizationReport;

import org.example.ticketing_app.mapper.OrganizationReportMapper;

/**
 * <p>
 * 服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
@RequiredArgsConstructor
public class OrganizationReportServiceImpl
        extends ServiceImpl<OrganizationReportMapper, OrganizationReport> {

    private final OrganizationMapper organizationMapper;
    private final TeamMapper teamMapper;
    private final TeamMemberMapper teamMemberMapper;
    private final TicketAssignmentMapper ticketAssignmentMapper;
    private final TicketMapper ticketMapper;
    private final ManagerMapper managerMapper;
    private final UserMapper userMapper;

    @Transactional
    public OrganizationReport generateReport(int organizationId) {

        Organization organization =
                organizationMapper.selectById(organizationId);

        if (organization == null) {
            throw new RuntimeException(
                    "Organization not found");
        }

        List<Manager> managers =
                managerMapper.selectList(
                        new LambdaQueryWrapper<Manager>()
                                .eq(
                                        Manager::getOrganizationId,
                                        organizationId)
                );

        String managerNames =
                managers.stream()
                        .map(manager ->
                                userMapper.selectById(
                                        manager.getUserId()))
                        .filter(Objects::nonNull)
                        .map(User::getName)
                        .collect(Collectors.joining(", "));

        List<Team> teams =
                teamMapper.selectList(
                        new LambdaQueryWrapper<Team>()
                                .eq(
                                        Team::getOrganizationId,
                                        organizationId)
                );

        int totalTeams = teams.size();
        int totalMembers = 0;
        int totalAssigned = 0;
        int totalCompleted = 0;
        int totalInProgress = 0;
        int totalRevenue = 0;

        StringBuilder body = new StringBuilder();

        body.append("Organization: ")
                .append(organization.getName())
                .append("\n");

        body.append("Manager(s): ")
                .append(
                        managerNames.isBlank()
                                ? "None"
                                : managerNames)
                .append("\n");

        body.append("Generated: ")
                .append(LocalDateTime.now())
                .append("\n\n");

        StringBuilder teamDetails =
                new StringBuilder();

        for (Team team : teams) {

            List<TeamMember> teamMembers =
                    teamMemberMapper.selectList(
                            new LambdaQueryWrapper<TeamMember>()
                                    .eq(
                                            TeamMember::getTeamId,
                                            team.getIdTeam())
                    );

            int memberCount = teamMembers.size();

            int teamAssigned = 0;
            int teamCompleted = 0;
            int teamInProgress = 0;
            int teamRevenue = 0;

            totalMembers += memberCount;

            for (TeamMember teamMember : teamMembers) {

                List<TicketAssignment> assignments =
                        ticketAssignmentMapper.selectList(
                                new LambdaQueryWrapper<TicketAssignment>()
                                        .eq(
                                                TicketAssignment::getAssigneeId,
                                                teamMember.getUserId())
                        );

                teamAssigned += assignments.size();
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

                    if (status == TicketStatus.CLOSED) {

                        teamCompleted++;
                        totalCompleted++;

                        teamRevenue += ticket.getPay();
                        totalRevenue += ticket.getPay();

                    } else if (status == TicketStatus.IN_PROGRESS) {

                        teamInProgress++;
                        totalInProgress++;
                    }
                }
            }

            teamDetails.append("Team: ")
                    .append(team.getName())
                    .append("\n");

            teamDetails.append("Members: ")
                    .append(memberCount)
                    .append("\n");

            teamDetails.append("Assigned jobs: ")
                    .append(teamAssigned)
                    .append("\n");

            teamDetails.append("Completed jobs: ")
                    .append(teamCompleted)
                    .append("\n");

            teamDetails.append("Jobs in progress: ")
                    .append(teamInProgress)
                    .append("\n");

            teamDetails.append("Revenue earned: $")
                    .append(teamRevenue)
                    .append("\n\n");
        }

        body.append("Organization Statistics\n");
        body.append("-----------------------\n");

        body.append("Total teams: ")
                .append(totalTeams)
                .append("\n");

        body.append("Total members: ")
                .append(totalMembers)
                .append("\n");

        body.append("Total assigned jobs: ")
                .append(totalAssigned)
                .append("\n");

        body.append("Total completed jobs: ")
                .append(totalCompleted)
                .append("\n");

        body.append("Total jobs in progress: ")
                .append(totalInProgress)
                .append("\n");

        body.append("Total revenue earned: $")
                .append(totalRevenue)
                .append("\n\n");

        body.append("Team Breakdown\n");
        body.append("--------------\n");
        body.append(teamDetails);

        OrganizationReport report =
                new OrganizationReport();

        report.setOrganizationId(
                organizationId);

        report.setTitle(
                "Organization Performance Report - "
                        + organization.getName());

        report.setBody(
                body.toString());

        report.setDateGenerated(
                LocalDateTime.now());

        save(report);

        return report;
    }
}

