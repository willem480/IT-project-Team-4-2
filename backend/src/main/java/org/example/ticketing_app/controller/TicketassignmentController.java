package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.TicketAssignmentServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 *.
 *
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/ticketAssignment")
@RequiredArgsConstructor
public class TicketassignmentController {
    private final TicketAssignmentServiceImpl ticketAssignmentService;

    //example: POST /getAcceptedJobsWithFilter?assigneeID=2001&filter=timeAscending
    //example with no filter: POST /getAcceptedJobsWithFilter?assigneeID=2001
    @PostMapping("getAcceptedJobsWithFilter")
    public List<TicketAssignmentReturn> getTicketAssignmentFilter(
            @RequestParam Integer assigneeID,
            @RequestParam(required = false) Filter filter) {
        if (filter == null) return ticketAssignmentService.getTicketAssignment(assigneeID);
        else return ticketAssignmentService.getTicketAssignment(assigneeID, filter);
    }

    @PostMapping("getAcceptedJobsKeyWord")
    public List<TicketAssignmentReturn> getTicketAssignmentKeyWord(@RequestParam Integer assigneeID, @RequestParam(required = false) String keyword) {
        if (keyword == null) return ticketAssignmentService.getTicketAssignment(assigneeID);
        else return ticketAssignmentService.getTicketAssignmentKeyWord(assigneeID, keyword);
    }

    @PostMapping("getAcceptedJobsRelatedTo")
    public List<TicketAssignmentReturn> getTicketAssignmentRelatedTo(@RequestParam Integer assigneeID, @RequestParam Integer teamID) {
        return ticketAssignmentService.getTicketAssignmentRelatedTo(assigneeID, teamID);
    }
}
