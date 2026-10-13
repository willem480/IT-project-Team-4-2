package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** One manager returned for an organization-management page. */
@Getter
@AllArgsConstructor
public class OrganizationManagerSummary {

    private final Integer managerId;
    private final Integer userId;
    private final String userName;
    private final String email;
}
