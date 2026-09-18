package org.example.ticketing_app.service.ticketServiceHelper;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

/** Request payload submitted by the app when a user posts a ticket manually. */
@Getter
@Setter
public class CreateTicketRequest {

    @NotNull(message = "posterId is required")
    private Integer posterId;

    @NotBlank(message = "title is required")
    @Size(max = 998, message = "title must not exceed 998 characters")
    private String title;

    @NotBlank(message = "description is required")
    private String description;

    @NotBlank(message = "location is required")
    @Size(max = 300, message = "location must not exceed 300 characters")
    private String location;

    @NotNull(message = "pay is required")
    @Positive(message = "pay must be a positive integer")
    private Integer pay;
}
