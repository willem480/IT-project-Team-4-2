package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.OrganizationReport;
import org.example.ticketing_app.service.impl.OrganizationReportServiceImpl;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/organizationReport")
@RequiredArgsConstructor
public class OrganizationreportController {
    private final OrganizationReportServiceImpl organizationReportService;

    @PostMapping("generateOrganizationReport")
    public OrganizationReport generateOrganizationReport(@RequestParam int organizationId) {
        return organizationReportService.generateReport(organizationId);
    }
}
