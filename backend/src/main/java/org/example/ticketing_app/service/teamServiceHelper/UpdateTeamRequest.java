package org.example.ticketing_app.service.teamServiceHelper;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/** Request body for renaming a team. */
@Getter
@Setter
public class UpdateTeamRequest {

    /** User attempting the change; this user must manage the team's organization. */
    @NotNull
    private Integer actorUserId;

    @NotNull
    private Integer teamId;

    @NotBlank
    @Size(max = 200)
    private String name;
}
