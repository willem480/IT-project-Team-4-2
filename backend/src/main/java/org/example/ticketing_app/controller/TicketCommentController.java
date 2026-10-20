package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.TicketComment;
import org.example.ticketing_app.service.impl.TicketCommentServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.TicketCommentReturn;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Controller;

import java.util.List;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-27
 */
@RestController
@RequestMapping("/ticketComment")
@RequiredArgsConstructor
public class TicketCommentController {
    private final TicketCommentServiceImpl ticketCommentService;

    @PostMapping("getTicketComments")
    public List<TicketCommentReturn> getTicketComments(@RequestParam int operatorId, @RequestParam int ticketId) {
        return ticketCommentService.getTicketCommentByTicketID(operatorId, ticketId);
    }

    @GetMapping("deleteComment")
    public boolean deleteComment(@RequestParam int operatorId, @RequestParam int ticketCommentId) {
        return ticketCommentService.deleteTicketComment(operatorId, ticketCommentId);
    }

    @PostMapping("postComment")
    public void postComment(@RequestParam int userId, @RequestParam int ticketId, @RequestParam String comment) {
        ticketCommentService.postComment(userId, ticketId, comment);
    }
}
