package org.example.ticketing_app.service.organizationServiceHelper;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** Request body for granting a user manager permission in one organization. */
@Getter
@Setter
public class AddManagerRequest {

    /** User attempting the change; this user must manage organizationId. */
    @NotNull
    private Integer actorUserId;

    @NotNull
    private Integer organizationId;

    /** Existing user who will become a manager. */
    @NotNull
    private Integer userId;
}
