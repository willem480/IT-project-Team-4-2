package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.TicketAssignmentServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/ticketAssignment")
@RequiredArgsConstructor
public class TicketassignmentController {
    private final TicketAssignmentServiceImpl ticketAssignmentService;

    @PostMapping("getAcceptedJobs")
    public List<TicketAssignmentReturn> getTicketAssignmentByAssigneeID(Integer assigneeID) {
        return ticketAssignmentService.getTicketAssignmentByAssigneeID(assigneeID);
    }
}
