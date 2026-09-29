package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.OrganizationServiceImpl;
import org.example.ticketing_app.service.organizationServiceHelper.AddTeamRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationSummary;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/organization")
@RequiredArgsConstructor
public class OrganizationController {
    private final OrganizationServiceImpl organizationService;

    /** Lists every organization with its member count and the viewer's manager permission. */
    @GetMapping("getOrganizations")
    public List<OrganizationSummary> getOrganizations(
            @RequestParam(required = false) Integer viewerUserId
    ) {
        return organizationService.getOrganizations(viewerUserId);
    }

    /** Lists the teams that belong to one organization. */
    @GetMapping("getOrganizationTeams")
    public OrganizationTeamListResponse getOrganizationTeams(
            @RequestParam Integer organizationId,
            @RequestParam(required = false) Integer viewerUserId
    ) {
        return organizationService.getOrganizationTeams(organizationId, viewerUserId);
    }

    /** Adds a team after verifying that the acting user manages the organization. */
    @PostMapping("addTeam")
    @ResponseStatus(HttpStatus.CREATED)
    public OrganizationTeamSummary addTeam(
            @Valid @RequestBody AddTeamRequest request
    ) {
        return organizationService.addTeam(request);
    }

    /** Removes an empty team after verifying manager permission again. */
    @DeleteMapping("removeTeam")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeTeam(
            @RequestParam Integer actorUserId,
            @RequestParam Integer organizationId,
            @RequestParam Integer teamId
    ) {
        organizationService.removeTeam(actorUserId, organizationId, teamId);
    }
}
