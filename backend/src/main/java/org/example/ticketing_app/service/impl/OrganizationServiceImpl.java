package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Manager;
import org.example.ticketing_app.entity.Organization;
import org.example.ticketing_app.entity.Team;
import org.example.ticketing_app.entity.TeamMember;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.TicketAssignment;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.ManagerMapper;
import org.example.ticketing_app.mapper.OrganizationMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TeamMapper;
import org.example.ticketing_app.mapper.TeamMemberMapper;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.organizationServiceHelper.AddManagerRequest;
import org.example.ticketing_app.service.organizationServiceHelper.AddTeamRequest;
import org.example.ticketing_app.service.organizationServiceHelper.CreateOrganizationRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationManagerSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationSummary;
import org.example.ticketing_app.service.organizationServiceHelper.UpdateOrganizationRequest;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

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
    private final TicketMapper ticketMapper;
    private final UserMapper userMapper;

    /** Creates an organization and makes its creator the first manager in one transaction. */
    @Transactional
    public OrganizationSummary createOrganization(CreateOrganizationRequest request) {
        requireUser(request.getActorUserId());
        String name = normalizeName(request.getName());
        requireUniqueOrganizationName(name, null);

        Organization organization = new Organization();
        organization.setName(name);
        save(organization);

        Manager manager = new Manager();
        manager.setOrganizationId(organization.getIdOrganization());
        manager.setUserId(request.getActorUserId());
        managerMapper.insert(manager);

        return toOrganizationSummary(organization, request.getActorUserId());
    }

    /**
     * Returns only organizations where the viewer is a team member or manager.
     * viewerUserId is temporary request context until authentication supplies the current user.
     */
    public List<OrganizationSummary> getOrganizations(Integer viewerUserId) {
        requireUser(viewerUserId);

        Set<Integer> visibleOrganizationIds = new HashSet<>();
        teamMemberMapper.selectList(
                        new LambdaQueryWrapper<TeamMember>()
                                .eq(TeamMember::getUserId, viewerUserId)
                ).stream()
                .map(TeamMember::getOrganizationId)
                .filter(Objects::nonNull)
                .forEach(visibleOrganizationIds::add);
        managerMapper.selectList(
                        new LambdaQueryWrapper<Manager>()
                                .eq(Manager::getUserId, viewerUserId)
                ).stream()
                .map(Manager::getOrganizationId)
                .filter(Objects::nonNull)
                .forEach(visibleOrganizationIds::add);

        return list().stream()
                .filter(organization -> visibleOrganizationIds.contains(organization.getIdOrganization()))
                .map(organization -> toOrganizationSummary(organization, viewerUserId))
                .toList();
    }

    /** Renames an organization after enforcing its manager permission. */
    @Transactional
    public OrganizationSummary updateOrganization(UpdateOrganizationRequest request) {
        Organization organization = requireOrganization(request.getOrganizationId());
        requireManager(request.getActorUserId(), organization.getIdOrganization());

        String name = normalizeName(request.getName());
        requireUniqueOrganizationName(name, organization.getIdOrganization());
        organization.setName(name);
        updateById(organization);

        return toOrganizationSummary(organization, request.getActorUserId());
    }

    /** Returns manager records with user details so the UI can select a manager to remove. */
    public List<OrganizationManagerSummary> getOrganizationManagers(Integer organizationId) {
        requireOrganization(organizationId);
        return managerMapper.selectList(
                        new LambdaQueryWrapper<Manager>()
                                .eq(Manager::getOrganizationId, organizationId)
                ).stream()
                .map(this::toManagerSummary)
                .toList();
    }

    /**
     * Returns every team membership in an organization.
     * Each result includes both IDs required to remove that exact membership later.
     */
    public List<OrganizationMemberSummary> getOrganizationMembers(
            Integer organizationId,
            Integer viewerUserId
    ) {
        requireOrganizationViewer(viewerUserId, organizationId);
        return teamMemberMapper.selectList(
                        new LambdaQueryWrapper<TeamMember>()
                                .eq(TeamMember::getOrganizationId, organizationId)
                ).stream()
                .map(this::toOrganizationMemberSummary)
                .toList();
    }

    /** Grants manager permission to an existing user after the acting manager is verified. */
    @Transactional
    public OrganizationManagerSummary addManager(AddManagerRequest request) {
        requireOrganization(request.getOrganizationId());
        requireManager(request.getActorUserId(), request.getOrganizationId());
        requireUser(request.getUserId());

        if (isManager(request.getUserId(), request.getOrganizationId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "User is already a manager of this organization");
        }

        Manager manager = new Manager();
        manager.setUserId(request.getUserId());
        manager.setOrganizationId(request.getOrganizationId());
        managerMapper.insert(manager);
        return toManagerSummary(manager);
    }

    /** Revokes one manager role but prevents an organization from becoming unmanaged. */
    @Transactional
    public void removeManager(Integer actorUserId, Integer organizationId, Integer managerId) {
        requireOrganization(organizationId);
        requireManager(actorUserId, organizationId);

        Manager manager = managerMapper.selectById(managerId);
        if (manager == null || !Objects.equals(manager.getOrganizationId(), organizationId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "Manager does not exist in the organization");
        }

        Long managerCount = managerMapper.selectCount(
                new LambdaQueryWrapper<Manager>()
                        .eq(Manager::getOrganizationId, organizationId)
        );
        if (managerCount == null || managerCount <= 1) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "An organization must retain at least one manager");
        }
        managerMapper.deleteById(managerId);
    }

    /** Returns organization teams and whether the current viewer may manage them. */
    public OrganizationTeamListResponse getOrganizationTeams(
            Integer organizationId,
            Integer viewerUserId
    ) {
        requireOrganizationViewer(viewerUserId, organizationId);

        List<OrganizationTeamSummary> teams = teamMapper.selectList(
                new LambdaQueryWrapper<Team>()
                                .eq(Team::getOrganizationId, organizationId)
                ).stream()
                .map(team -> toTeamSummary(team, viewerUserId))
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
        return toTeamSummary(team, request.getActorUserId());
    }

    /**
     * Removes one team and its membership records without deleting user accounts.
     * Assignment handling preserves closed-ticket history while releasing team references.
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
        List<TicketAssignment> assignments = ticketAssignmentMapper.selectList(
                new LambdaQueryWrapper<TicketAssignment>()
                        .eq(TicketAssignment::getRelatedTeamId, teamId)
        );

        for (TicketAssignment assignment : assignments) {
            Ticket ticket = ticketMapper.selectById(assignment.getTicketId());
            if (ticket == null) {
                // Remove an orphaned assignment so it cannot retain the team foreign key.
                ticketAssignmentMapper.deleteById(assignment.getIdTicketAssignment());
                continue;
            }

            if (TicketStatus.IN_PROGRESS.name().equals(ticket.getStatus())) {
                // Reopen active work when the team responsible for it is removed.
                ticketAssignmentMapper.deleteById(assignment.getIdTicketAssignment());
                ticket.setStatus(TicketStatus.OPEN.name());
                ticketMapper.updateById(ticket);
            } else if (TicketStatus.CLOSED.name().equals(ticket.getStatus())) {
                // Preserve the closed assignment history, but detach the deleted team.
                assignment.setRelatedTeamId(null);
                ticketAssignmentMapper.updateById(assignment);
            } else {
                // Open and cancelled tickets keep their status but cannot retain this team reference.
                ticketAssignmentMapper.deleteById(assignment.getIdTicketAssignment());
            }
        }

        List<TeamMember> memberships = teamMemberMapper.selectList(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getTeamId, teamId)
        );
        for (TeamMember membership : memberships) {
            teamMemberMapper.deleteById(membership.getIdTeamMember());
        }
        teamMapper.deleteById(teamId);
    }

    /** A user can manage an organization only when a matching manager row exists. */
    private boolean canManageOrganization(Integer viewerUserId, Integer organizationId) {
        return viewerUserId != null && isManager(viewerUserId, organizationId);
    }

    /** Rejects every team change made by a user who is not an organization manager. */
    private void requireManager(Integer actorUserId, Integer organizationId) {
        if (!canManageOrganization(actorUserId, organizationId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only an organization manager can change members");
        }
    }

    private boolean isManager(Integer userId, Integer organizationId) {
        Long managerCount = managerMapper.selectCount(
                new LambdaQueryWrapper<Manager>()
                        .eq(Manager::getUserId, userId)
                        .eq(Manager::getOrganizationId, organizationId)
        );
        return managerCount != null && managerCount > 0;
    }

    /** Rejects viewers who are neither managers nor team members of the requested organization. */
    private void requireOrganizationViewer(Integer viewerUserId, Integer organizationId) {
        requireUser(viewerUserId);
        requireOrganization(organizationId);
        if (isManager(viewerUserId, organizationId)) {
            return;
        }
        Long membershipCount = teamMemberMapper.selectCount(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getUserId, viewerUserId)
                        .eq(TeamMember::getOrganizationId, organizationId)
        );
        if (membershipCount == null || membershipCount == 0) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "You do not belong to this organization");
        }
    }

    private User requireUser(Integer userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User does not exist");
        }
        return user;
    }

    private String normalizeName(String name) {
        return name.trim();
    }

    private void requireUniqueOrganizationName(String name, Integer excludedOrganizationId) {
        Long sameNameCount = list().stream()
                .filter(organization -> !Objects.equals(organization.getIdOrganization(), excludedOrganizationId))
                .map(Organization::getName)
                .filter(Objects::nonNull)
                .filter(existingName -> existingName.equalsIgnoreCase(name))
                .count();
        if (sameNameCount > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "An organization with this name already exists");
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

    private OrganizationSummary toOrganizationSummary(Organization organization, Integer viewerUserId) {
        return new OrganizationSummary(
                organization.getIdOrganization(),
                organization.getName(),
                countMembers(organization.getIdOrganization()),
                canManageOrganization(viewerUserId, organization.getIdOrganization())
        );
    }

    private OrganizationManagerSummary toManagerSummary(Manager manager) {
        User user = requireUser(manager.getUserId());
        return new OrganizationManagerSummary(
                manager.getIdManager(),
                user.getIdUser(),
                user.getName(),
                user.getEmail()
        );
    }

    private OrganizationMemberSummary toOrganizationMemberSummary(TeamMember membership) {
        User user = userMapper.selectById(membership.getUserId());
        return new OrganizationMemberSummary(
                membership.getIdTeamMember(),
                membership.getTeamId(),
                membership.getUserId(),
                user == null ? null : user.getName(),
                user == null ? null : user.getEmail()
        );
    }

    /** Builds one team response including whether the current viewer belongs to that team. */
    private OrganizationTeamSummary toTeamSummary(Team team, Integer viewerUserId) {
        return new OrganizationTeamSummary(
                team.getIdTeam(),
                team.getName(),
                countTeamMembers(team.getIdTeam()),
                isTeamMember(team.getIdTeam(), viewerUserId)
        );
    }

    private boolean isTeamMember(Integer teamId, Integer userId) {
        if (userId == null) {
            return false;
        }
        Long membershipCount = teamMemberMapper.selectCount(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getTeamId, teamId)
                        .eq(TeamMember::getUserId, userId)
        );
        return membershipCount != null && membershipCount > 0;
    }
}
