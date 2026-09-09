package org.example.ticketing_app.controller;

import org.example.ticketing_app.service.impl.TicketServiceImpl;
import org.example.ticketing_app.service.ticketService.TicketService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Controller
@RequestMapping("/ticket")
@ResponseBody
public class TicketController {
    TicketServiceImpl ticketService = new TicketServiceImpl();
    @GetMapping("getAllTickets")
    public String getAllTickets() {
        return ticketService.getAllTickets();
    }
}
