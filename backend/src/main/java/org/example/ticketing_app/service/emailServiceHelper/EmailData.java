package org.example.ticketing_app.service.emailServiceHelper;

public record EmailData(
        String messageId,
        String from,
        String subject,
        String body
) {}

