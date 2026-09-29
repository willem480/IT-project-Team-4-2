package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.TicketComment;
import org.example.ticketing_app.service.impl.TicketCommentServiceImpl;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

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
    public List<TicketComment> getTicketComments(@RequestParam int ticketId) {
        return ticketCommentService.getTicketCommentByTicketID(ticketId);
    }

    @PostMapping("postComment")
    public void postComment(@RequestParam int userId, @RequestParam int ticketId, @RequestParam String comment) {
        ticketCommentService.postComment(userId, ticketId, comment);
    }
}
