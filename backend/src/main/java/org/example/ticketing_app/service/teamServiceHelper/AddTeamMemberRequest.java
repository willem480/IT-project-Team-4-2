package org.example.ticketing_app.service.teamServiceHelper;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/** Request body for adding a user to a team. */
@Getter
@Setter
public class AddTeamMemberRequest {

    /** User attempting the change; this user must manage the team's organization. */
    @NotNull
    private Integer actorUserId;

    @NotNull
    private Integer teamId;

    @NotNull
    private Integer userId;
}
