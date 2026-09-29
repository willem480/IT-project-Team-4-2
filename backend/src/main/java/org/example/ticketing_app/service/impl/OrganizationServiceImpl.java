package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Manager;
import org.example.ticketing_app.entity.Organization;
import org.example.ticketing_app.entity.Team;
import org.example.ticketing_app.entity.TeamMember;
import org.example.ticketing_app.entity.TicketAssignment;
import org.example.ticketing_app.mapper.ManagerMapper;
import org.example.ticketing_app.mapper.OrganizationMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TeamMapper;
import org.example.ticketing_app.mapper.TeamMemberMapper;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import org.example.ticketing_app.service.organizationServiceHelper.AddTeamRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationSummary;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Objects;

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
public class OrganizationServiceImpl extends ServiceImpl<OrganizationMapper, Organization> {

    private final ManagerMapper managerMapper;
    private final TeamMemberMapper teamMemberMapper;
    private final TeamMapper teamMapper;
    private final TicketAssignmentMapper ticketAssignmentMapper;

    /**
     * Returns the organization cards needed by the organization-list page.
     * viewerUserId is temporary request context until authentication supplies the current user.
     */
    public List<OrganizationSummary> getOrganizations(Integer viewerUserId) {
        return list().stream()
                .map(organization -> new OrganizationSummary(
                        organization.getIdOrganization(),
                        organization.getName(),
                        countMembers(organization.getIdOrganization()),
                        canManageOrganization(viewerUserId, organization.getIdOrganization())
                ))
                .toList();
    }

    /** Returns organization teams and whether the current viewer may manage them. */
    public OrganizationTeamListResponse getOrganizationTeams(
            Integer organizationId,
            Integer viewerUserId
    ) {
        requireOrganization(organizationId);

        List<OrganizationTeamSummary> teams = teamMapper.selectList(
                        new LambdaQueryWrapper<Team>()
                                .eq(Team::getOrganizationId, organizationId)
                ).stream()
                .map(this::toTeamSummary)
                .toList();

        return new OrganizationTeamListResponse(
                organizationId,
                canManageOrganization(viewerUserId, organizationId),
                teams
        );
    }

    /** Creates one team in an organization after enforcing the manager permission. */
    @Transactional
    public OrganizationTeamSummary addTeam(AddTeamRequest request) {
        requireOrganization(request.getOrganizationId());
        requireManager(request.getActorUserId(), request.getOrganizationId());

        Long duplicateNames = teamMapper.selectCount(
                new LambdaQueryWrapper<Team>()
                        .eq(Team::getOrganizationId, request.getOrganizationId())
                        .eq(Team::getName, request.getName().trim())
        );
        if (duplicateNames != null && duplicateNames > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "A team with this name already exists in the organization");
        }

        Team team = new Team();
        team.setOrganizationId(request.getOrganizationId());
        team.setName(request.getName().trim());
        teamMapper.insert(team);
        return toTeamSummary(team);
    }

    /**
     * Removes an empty team only. Membership and assignment records are retained,
     * so callers must first remove members and resolve historical assignments.
     */
    @Transactional
    public void removeTeam(
            Integer actorUserId,
            Integer organizationId,
            Integer teamId
    ) {
        requireOrganization(organizationId);
        requireManager(actorUserId, organizationId);

        Team team = teamMapper.selectById(teamId);
        if (team == null || !Objects.equals(team.getOrganizationId(), organizationId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Team does not exist in the organization");
        }
        if (countTeamMembers(teamId) > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Remove all team members before deleting the team");
        }
        Long assignmentCount = ticketAssignmentMapper.selectCount(
                new LambdaQueryWrapper<TicketAssignment>()
                        .eq(TicketAssignment::getRelatedTeamId, teamId)
        );
        if (assignmentCount != null && assignmentCount > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Team has ticket assignments and cannot be deleted");
        }
        teamMapper.deleteById(teamId);
    }

    /** A user can manage an organization only when a matching manager row exists. */
    private boolean canManageOrganization(Integer viewerUserId, Integer organizationId) {
        if (viewerUserId == null) {
            return false;
        }
        Long managerCount = managerMapper.selectCount(
                new LambdaQueryWrapper<Manager>()
                        .eq(Manager::getUserId, viewerUserId)
                        .eq(Manager::getOrganizationId, organizationId)
        );
        return managerCount != null && managerCount > 0;
    }

    /** Rejects every team change made by a user who is not an organization manager. */
    private void requireManager(Integer actorUserId, Integer organizationId) {
        if (!canManageOrganization(actorUserId, organizationId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only an organization manager can change members");
        }
    }

    private long countMembers(Integer organizationId) {
        return teamMemberMapper.selectList(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getOrganizationId, organizationId)
        ).stream()
                .map(TeamMember::getUserId)
                .filter(Objects::nonNull)
                .distinct()
                .count();
    }

    private long countTeamMembers(Integer teamId) {
        Long memberCount = teamMemberMapper.selectCount(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getTeamId, teamId)
        );
        return memberCount == null ? 0 : memberCount;
    }

    private Organization requireOrganization(Integer organizationId) {
        Organization organization = getById(organizationId);
        if (organization == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Organization does not exist");
        }
        return organization;
    }

    private OrganizationTeamSummary toTeamSummary(Team team) {
        return new OrganizationTeamSummary(
                team.getIdTeam(),
                team.getName(),
                countTeamMembers(team.getIdTeam())
        );
    }
}
