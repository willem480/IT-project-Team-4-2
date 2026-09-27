package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** Organization-card data returned to the organization-list page. */
@Getter
@AllArgsConstructor
public class OrganizationSummary {

    private final Integer organizationId;
    private final String name;
    private final long memberCount;
    private final boolean canManage;
}
