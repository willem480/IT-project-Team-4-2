package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.OrganizationServiceImpl;
import org.example.ticketing_app.service.organizationServiceHelper.AddManagerRequest;
import org.example.ticketing_app.service.organizationServiceHelper.AddTeamRequest;
import org.example.ticketing_app.service.organizationServiceHelper.CreateOrganizationRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationManagerSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationTeamSummary;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationSummary;
import org.example.ticketing_app.service.organizationServiceHelper.UpdateOrganizationRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PatchMapping;
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

    /** Creates an organization and grants its creator the first manager role. */
    @PostMapping("createOrganization")
    @ResponseStatus(HttpStatus.CREATED)
    public OrganizationSummary createOrganization(
            @Valid @RequestBody CreateOrganizationRequest request
    ) {
        return organizationService.createOrganization(request);
    }

    /** Lists every organization with its member count and the viewer's manager permission. */
    @GetMapping("getOrganizations")
    public List<OrganizationSummary> getOrganizations(
            @RequestParam Integer viewerUserId
    ) {
        return organizationService.getOrganizations(viewerUserId);
    }

    /** Renames an organization after verifying its manager permission. */
    @PatchMapping("updateOrganization")
    public OrganizationSummary updateOrganization(
            @Valid @RequestBody UpdateOrganizationRequest request
    ) {
        return organizationService.updateOrganization(request);
    }

    /** Lists the users who currently manage one organization. */
    @GetMapping("getOrganizationManagers")
    public List<OrganizationManagerSummary> getOrganizationManagers(
            @RequestParam Integer organizationId
    ) {
        return organizationService.getOrganizationManagers(organizationId);
    }

    /** Lists all team memberships in an organization, including membership and team IDs. */
    @GetMapping("getOrganizationMembers")
    public List<OrganizationMemberSummary> getOrganizationMembers(
            @RequestParam Integer organizationId,
            @RequestParam Integer viewerUserId
    ) {
        return organizationService.getOrganizationMembers(organizationId, viewerUserId);
    }

    /** Grants manager permission to an existing user. */
    @PostMapping("addManager")
    @ResponseStatus(HttpStatus.CREATED)
    public OrganizationManagerSummary addManager(
            @Valid @RequestBody AddManagerRequest request
    ) {
        return organizationService.addManager(request);
    }

    /** Revokes manager permission while ensuring at least one manager remains. */
    @DeleteMapping("removeManager")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeManager(
            @RequestParam Integer actorUserId,
            @RequestParam Integer organizationId,
            @RequestParam Integer managerId
    ) {
        organizationService.removeManager(actorUserId, organizationId, managerId);
    }

    /** Lists the teams that belong to one organization. */
    @GetMapping("getOrganizationTeams")
    public OrganizationTeamListResponse getOrganizationTeams(
            @RequestParam Integer organizationId,
            @RequestParam Integer viewerUserId
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
