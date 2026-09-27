package org.example.ticketing_app.service.organizationServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

/** Member-list data and the permission used to decide whether edit controls are shown. */
@Getter
@AllArgsConstructor
public class OrganizationMemberListResponse {

    private final Integer organizationId;
    private final boolean canManage;
    private final List<OrganizationMemberSummary> members;
}
