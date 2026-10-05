package org.example.ticketing_app.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.TeamServiceImpl;
import org.example.ticketing_app.service.teamServiceHelper.AddTeamMemberRequest;
import org.example.ticketing_app.service.teamServiceHelper.TeamMemberListResponse;
import org.example.ticketing_app.service.teamServiceHelper.TeamMemberSummary;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/team")
@RequiredArgsConstructor
public class TeamController {

    private final TeamServiceImpl teamService;

    /** Lists the users assigned to one team. */
    @GetMapping("getTeamMembers")
    public TeamMemberListResponse getTeamMembers(
            @RequestParam Integer teamId,
            @RequestParam(required = false) Integer viewerUserId
    ) {
        return teamService.getTeamMembers(teamId, viewerUserId);
    }

    /** Adds a user to a team after checking the manager permission of its organization. */
    @PostMapping("addTeamMember")
    @ResponseStatus(HttpStatus.CREATED)
    public TeamMemberSummary addTeamMember(
            @Valid @RequestBody AddTeamMemberRequest request
    ) {
        return teamService.addTeamMember(request);
    }

    /** Removes one user-to-team membership after checking manager permission. */
    @DeleteMapping("removeTeamMember")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeTeamMember(
            @RequestParam Integer actorUserId,
            @RequestParam Integer teamId,
            @RequestParam Integer teamMemberId
    ) {
        teamService.removeTeamMember(actorUserId, teamId, teamMemberId);
    }

}
