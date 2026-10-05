package org.example.ticketing_app.service.teamServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

/** Member-list data and the permission used to decide whether member controls are shown. */
@Getter
@AllArgsConstructor
public class TeamMemberListResponse {

    private final Integer teamId;
    private final Integer organizationId;
    private final boolean canManage;
    private final List<TeamMemberSummary> members;
}
