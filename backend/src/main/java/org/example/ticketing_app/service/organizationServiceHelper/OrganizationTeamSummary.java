package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** One team card shown inside an organization. */
@Getter
@AllArgsConstructor
public class OrganizationTeamSummary {

    private final Integer teamId;
    private final String name;
    private final long memberCount;
}
