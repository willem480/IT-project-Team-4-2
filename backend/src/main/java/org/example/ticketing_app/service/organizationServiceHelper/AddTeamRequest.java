package org.example.ticketing_app.service.organizationServiceHelper;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/** Request body for creating a team in an organization. */
@Getter
@Setter
public class AddTeamRequest {

    /** User attempting the change; this user must manage organizationId. */
    @NotNull
    private Integer actorUserId;

    @NotNull
    private Integer organizationId;

    @NotBlank
    @Size(max = 200)
    private String name;
}
