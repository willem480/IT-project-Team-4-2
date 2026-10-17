package org.example.ticketing_app.service.userServiceHelper;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class SignInRequest {

    private String email;

}