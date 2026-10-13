package org.example.ticketing_app.service.organizationServiceHelper;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/** Request body for creating an organization and its first manager. */
@Getter
@Setter
public class CreateOrganizationRequest {

    /** The authenticated user represented temporarily by this request field. */
    @NotNull
    private Integer actorUserId;

    @NotBlank
    @Size(max = 200)
    private String name;
}
