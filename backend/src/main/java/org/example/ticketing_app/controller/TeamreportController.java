package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.TeamReport;
import org.example.ticketing_app.service.impl.TeamReportServiceImpl;
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
@RequestMapping("/teamReport")
@RequiredArgsConstructor
public class TeamreportController {
    private final TeamReportServiceImpl teamReportService;

    @PostMapping("generateTeamReport")
    public TeamReport generateTeamReport(@RequestParam int teamId) {
        return teamReportService.generateReport(teamId);
    }
}
