package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Manager;
import org.example.ticketing_app.entity.Team;
import org.example.ticketing_app.entity.TeamMember;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.ManagerMapper;
import org.example.ticketing_app.mapper.TeamMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TeamMemberMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.teamServiceHelper.AddTeamMemberRequest;
import org.example.ticketing_app.service.teamServiceHelper.TeamMemberListResponse;
import org.example.ticketing_app.service.teamServiceHelper.TeamMemberSummary;
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
public class TeamServiceImpl extends ServiceImpl<TeamMapper, Team> {

    private final TeamMemberMapper teamMemberMapper;
    private final UserMapper userMapper;
    private final ManagerMapper managerMapper;

    /** Returns team members and the current viewer's permission to edit the team. */
    public TeamMemberListResponse getTeamMembers(Integer teamId, Integer viewerUserId) {
        Team team = requireTeam(teamId);
        List<TeamMemberSummary> members = teamMemberMapper.selectList(
                        new LambdaQueryWrapper<TeamMember>()
                                .eq(TeamMember::getTeamId, teamId)
                ).stream()
                .map(this::toMemberSummary)
                .toList();

        return new TeamMemberListResponse(
                teamId,
                team.getOrganizationId(),
                canManageTeam(viewerUserId, team),
                members
        );
    }

    /** Adds one user-to-team membership after verifying the manager permission. */
    @Transactional
    public TeamMemberSummary addTeamMember(AddTeamMemberRequest request) {
        Team team = requireTeam(request.getTeamId());
        requireManager(request.getActorUserId(), team);

        if (userMapper.selectById(request.getUserId()) == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User does not exist");
        }
        Long existingMemberships = teamMemberMapper.selectCount(
                new LambdaQueryWrapper<TeamMember>()
                        .eq(TeamMember::getTeamId, request.getTeamId())
                        .eq(TeamMember::getUserId, request.getUserId())
        );
        if (existingMemberships != null && existingMemberships > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "User is already a member of this team");
        }

        TeamMember membership = new TeamMember();
        membership.setTeamId(team.getIdTeam());
        membership.setOrganizationId(team.getOrganizationId());
        membership.setUserId(request.getUserId());
        teamMemberMapper.insert(membership);
        return toMemberSummary(membership);
    }

    /** Removes exactly one team membership and preserves the user's memberships in other teams. */
    @Transactional
    public void removeTeamMember(Integer actorUserId, Integer teamId, Integer teamMemberId) {
        Team team = requireTeam(teamId);
        requireManager(actorUserId, team);

        TeamMember membership = teamMemberMapper.selectById(teamMemberId);
        if (membership == null || !Objects.equals(membership.getTeamId(), teamId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Team membership does not exist");
        }
        teamMemberMapper.deleteById(teamMemberId);
    }

    /** A manager is identified by a matching user and organization row in the manager table. */
    private boolean canManageTeam(Integer viewerUserId, Team team) {
        if (viewerUserId == null) {
            return false;
        }
        Long managerCount = managerMapper.selectCount(
                new LambdaQueryWrapper<Manager>()
                        .eq(Manager::getUserId, viewerUserId)
                        .eq(Manager::getOrganizationId, team.getOrganizationId())
        );
        return managerCount != null && managerCount > 0;
    }

    /** Rejects changes from users who do not manage the team's organization. */
    private void requireManager(Integer actorUserId, Team team) {
        if (!canManageTeam(actorUserId, team)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only an organization manager can change team members");
        }
    }

    private Team requireTeam(Integer teamId) {
        Team team = getById(teamId);
        if (team == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Team does not exist");
        }
        return team;
    }

    private TeamMemberSummary toMemberSummary(TeamMember membership) {
        User user = userMapper.selectById(membership.getUserId());
        return new TeamMemberSummary(
                membership.getIdTeamMember(),
                membership.getUserId(),
                user == null ? null : user.getName(),
                user == null ? null : user.getEmail()
        );
    }
}
