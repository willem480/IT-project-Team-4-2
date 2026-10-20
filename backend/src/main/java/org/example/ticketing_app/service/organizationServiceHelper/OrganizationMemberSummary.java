package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** One team membership returned while viewing all members of an organization. */
@Getter
@AllArgsConstructor
public class OrganizationMemberSummary {

    /** Required by the remove-team-member endpoint. */
    private final Integer teamMemberId;

    /** Identifies the team that owns this membership. */
    private final Integer teamId;

    private final Integer userId;
    private final String userName;
    private final String email;
}
