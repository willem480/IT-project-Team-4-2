package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

/** Team-list data and the permission used to decide whether team controls are shown. */
@Getter
@AllArgsConstructor
public class OrganizationTeamListResponse {

    private final Integer organizationId;
    private final boolean canManage;
    private final List<OrganizationTeamSummary> teams;
}
