package org.example.ticketing_app.service;

import org.springframework.stereotype.Service;

@Service
public class TicketService {

    public String getAllTickets() {
        return "get all tickets is working";
    }

    public String getTicketById(Long id) {
        return "Ticket " + id;
    }

}
