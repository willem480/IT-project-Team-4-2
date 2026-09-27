package org.example.ticketing_app.service.organizationServiceHelper;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** Request body for adding a user to an organization team. */
@Getter
@Setter
public class AddOrganizationMemberRequest {

    /** User attempting the change; this user must be a manager of organizationId. */
    @NotNull
    private Integer actorUserId;

    @NotNull
    private Integer organizationId;

    @NotNull
    private Integer teamId;

    @NotNull
    private Integer userId;
}
