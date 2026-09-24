package org.example.ticketing_app.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.service.impl.TicketServiceImpl;
import org.example.ticketing_app.service.ticketServiceHelper.CreateTicketRequest;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

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
@RequestMapping("/ticket")
@RequiredArgsConstructor
public class TicketController {

    private final TicketServiceImpl ticketService;

    /** Accepts a manual job post from the app and returns the created ticket. */
    @PostMapping("createTicket")
    @ResponseStatus(HttpStatus.CREATED)
    public Ticket createTicket(@Valid @RequestBody CreateTicketRequest request) {
        return ticketService.createTicket(request);
    }

    @PostMapping("getOpenTickets")
    public List<Ticket> getTickets(@RequestParam(required = false) Filter filter) {
        if (filter == null) {
            return ticketService.getOpenTickets();
        }
        else {
            return ticketService.getOpenTickets(filter);
        }
    }

    @PostMapping("getOpenTicketsByKeyword")
    public List<Ticket> getTicketsKeyword(String keyword){
        return ticketService.getOpenTicketsKeyword(keyword);
    }
}
