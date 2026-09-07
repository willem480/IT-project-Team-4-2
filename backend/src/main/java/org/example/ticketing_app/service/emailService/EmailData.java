package org.example.ticketing_app.service.emailService;

public record EmailData(
        String messageId,
        String from,
        String subject,
        String body
) {}

