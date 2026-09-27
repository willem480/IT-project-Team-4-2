package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Manager;
import org.example.ticketing_app.entity.Organization;
import org.example.ticketing_app.entity.Team;
import org.example.ticketing_app.entity.TeamMember;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.ManagerMapper;
import org.example.ticketing_app.mapper.OrganizationMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TeamMapper;
import org.example.ticketing_app.mapper.TeamMemberMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.organizationServiceHelper.AddOrganizationMemberRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberSummary;
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
    private final UserMapper userMapper;

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

    /** Returns organization members and whether the current viewer may edit them. */
    public OrganizationMemberListResponse getOrganizationMembers(
            Integer organizationId,
            Integer viewerUserId
    ) {
        requireOrganization(organizationId);

        List<OrganizationMemberSummary> members = teamMemberMapper.selectList(
                        new LambdaQueryWrapper<TeamMember>()
                                .eq(TeamMember::getOrganizationId, organizationId)
                ).stream()
                .map(this::toMemberSummary)
                .toList();

        return new OrganizationMemberListResponse(
                organizationId,
                canManageOrganization(viewerUserId, organizationId),
                members
        );
    }

    /**
     * Creates one user-to-team membership. The manager check is enforced here,
     * so callers cannot bypass it by hiding or changing a front-end button.
     */
    @Transactional
    public OrganizationMemberSummary addOrganizationMember(AddOrganizationMemberRequest request) {
        requireOrganization(request.getOrganizationId());
        requireManager(request.getActorUserId(), request.getOrganizationId());

        Team team = teamMapper.selectById(request.getTeamId());
        if (team == null || !Objects.equals(team.getOrganizationId(), request.getOrganizationId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Team does not belong to the organization");
        }
        if (userMapper.selectById(request.getUserId()) == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User does not exist");
        }

        Long existingMemberships = teamMemberMapper.selectCount(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getOrganizationId, request.getOrganizationId())
                        .eq(TeamMember::getTeamId, request.getTeamId())
                        .eq(TeamMember::getUserId, request.getUserId())
        );
        if (existingMemberships != null && existingMemberships > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "User is already a member of this team");
        }

        TeamMember membership = new TeamMember();
        membership.setOrganizationId(request.getOrganizationId());
        membership.setTeamId(request.getTeamId());
        membership.setUserId(request.getUserId());
        teamMemberMapper.insert(membership);
        return toMemberSummary(membership);
    }

    /** Removes exactly one membership record and does not affect the user's other teams. */
    @Transactional
    public void removeOrganizationMember(
            Integer actorUserId,
            Integer organizationId,
            Integer teamMemberId
    ) {
        requireOrganization(organizationId);
        requireManager(actorUserId, organizationId);

        TeamMember membership = teamMemberMapper.selectById(teamMemberId);
        if (membership == null || !Objects.equals(membership.getOrganizationId(), organizationId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "Organization membership does not exist");
        }
        teamMemberMapper.deleteById(teamMemberId);
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

    /** Rejects every membership change made by a user who is not an organization manager. */
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

    private Organization requireOrganization(Integer organizationId) {
        Organization organization = getById(organizationId);
        if (organization == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Organization does not exist");
        }
        return organization;
    }

    private OrganizationMemberSummary toMemberSummary(TeamMember membership) {
        User user = userMapper.selectById(membership.getUserId());
        Team team = teamMapper.selectById(membership.getTeamId());
        return new OrganizationMemberSummary(
                membership.getIdTeamMember(),
                membership.getUserId(),
                user == null ? null : user.getName(),
                user == null ? null : user.getEmail(),
                membership.getTeamId(),
                team == null ? null : team.getName()
        );
    }
}
