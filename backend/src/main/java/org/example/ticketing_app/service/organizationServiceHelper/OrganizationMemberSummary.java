package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** One user's membership in one team inside an organization. */
@Getter
@AllArgsConstructor
public class OrganizationMemberSummary {

    private final Integer teamMemberId;
    private final Integer userId;
    private final String userName;
    private final String email;
    private final Integer teamId;
    private final String teamName;
}
