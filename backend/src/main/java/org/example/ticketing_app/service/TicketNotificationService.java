package org.example.ticketing_app.service;

import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.service.emailServiceHelper.EmailServiceHelper;
import org.springframework.stereotype.Service;

@Service
public class TicketNotificationService {

    public void sendAssignedNotification(Ticket ticket, User poster, String assigneeName) {
        String subject = "Ticket Update - Ticket Assigned (#" + ticket.getIdTicket() + ")";
        String body =
                "Your ticket has been assigned.\n\n"
                        + "Ticket ID: " + ticket.getIdTicket() + "\n"
                        + "Title: " + ticket.getTitle() + "\n"
                        + "Assigned to: " + assigneeName + "\n"
                        + "Status: " + ticket.getStatus();

        sendToPoster(poster, subject, body);
    }

    public void sendCompletedNotification(Ticket ticket, User poster) {
        String subject = "Ticket Update - Ticket Completed (#" + ticket.getIdTicket() + ")";
        String body =
                "Your ticket has been completed.\n\n"
                        + "Ticket ID: " + ticket.getIdTicket() + "\n"
                        + "Title: " + ticket.getTitle() + "\n"
                        + "Status: " + ticket.getStatus();

        sendToPoster(poster, subject, body);
    }

    public void sendDeallocatedNotification(Ticket ticket, User poster) {
        String subject = "Ticket Update - Ticket Deallocated (#" + ticket.getIdTicket() + ")";
        String body =
                "The assignment for your ticket has been removed.\n\n"
                        + "Ticket ID: " + ticket.getIdTicket() + "\n"
                        + "Title: " + ticket.getTitle() + "\n"
                        + "Status: " + ticket.getStatus();

        sendToPoster(poster, subject, body);
    }

    public void sendCommentNotification(
            Ticket ticket,
            User poster,
            String commenterName,
            String commentContent
    ) {
        String subject = "Ticket Update - New Comment (#" + ticket.getIdTicket() + ")";
        String body =
                "A new comment has been added to your ticket.\n\n"
                        + "Ticket ID: " + ticket.getIdTicket() + "\n"
                        + "Title: " + ticket.getTitle() + "\n"
                        + "Comment by: " + commenterName + "\n"
                        + "Comment: " + commentContent;

        sendToPoster(poster, subject, body);
    }

    private void sendToPoster(User poster, String subject, String body) {
        if (poster == null || poster.getEmail() == null || poster.getEmail().isBlank()) {
            return;
        }

        try {
            EmailServiceHelper.sendEmail(
                    poster.getEmail(),
                    subject,
                    body
            );
        } catch (Exception e) {
            // Notification failure must not stop the original ticket operation.
            System.err.println("Failed to send ticket notification: " + e.getMessage());
        }
    }
}
