package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.MemberReport;
import org.example.ticketing_app.service.impl.MemberReportServiceImpl;
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
@RequestMapping("/memberReport")
@RequiredArgsConstructor
public class MemberreportController {
    private final MemberReportServiceImpl memberReportService;

    @PostMapping("generateTeamMemberReport")
    public MemberReport generateMemberReport(@RequestParam int userId, @RequestParam int teamId) {
        return memberReportService.generateTeamMemberReport(userId, teamId);
    }
}
