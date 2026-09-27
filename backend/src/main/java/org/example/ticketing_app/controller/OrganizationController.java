package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.OrganizationServiceImpl;
import org.example.ticketing_app.service.organizationServiceHelper.AddOrganizationMemberRequest;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberListResponse;
import org.example.ticketing_app.service.organizationServiceHelper.OrganizationMemberSummary;
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

    /** Lists the membership records for one organization. */
    @GetMapping("getOrganizationMembers")
    public OrganizationMemberListResponse getOrganizationMembers(
            @RequestParam Integer organizationId,
            @RequestParam(required = false) Integer viewerUserId
    ) {
        return organizationService.getOrganizationMembers(organizationId, viewerUserId);
    }

    /** Adds a user to a team after verifying that the acting user manages the organization. */
    @PostMapping("addOrganizationMember")
    @ResponseStatus(HttpStatus.CREATED)
    public OrganizationMemberSummary addOrganizationMember(
            @Valid @RequestBody AddOrganizationMemberRequest request
    ) {
        return organizationService.addOrganizationMember(request);
    }

    /** Removes one team-membership record after verifying manager permission again. */
    @DeleteMapping("removeOrganizationMember")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeOrganizationMember(
            @RequestParam Integer actorUserId,
            @RequestParam Integer organizationId,
            @RequestParam Integer teamMemberId
    ) {
        organizationService.removeOrganizationMember(actorUserId, organizationId, teamMemberId);
    }
}
