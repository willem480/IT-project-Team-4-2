package org.example.ticketing_app.service.teamServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

/** One user membership returned by the team page. */
@Getter
@AllArgsConstructor
public class TeamMemberSummary {

    private final Integer teamMemberId;
    private final Integer userId;
    private final String userName;
    private final String email;
}
