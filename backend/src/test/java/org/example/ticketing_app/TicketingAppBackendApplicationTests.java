package org.example.ticketing_app;

import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import org.example.ticketing_app.service.emailService.EmailData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.example.ticketing_app.service.emailService.*;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
@SpringBootTest
class TicketingAppBackendApplicationTests {
    @Autowired
    EmailService emailService;
    @Test
    void sendAndReceiveEmail() throws Exception {

        EmailSession session = emailService.readUnreadEmails();
        List<Message> messages = session.getMessages();

        Message latestMessage = messages.stream()
                .filter(m -> {
                    try {
                        return m.getSentDate() != null;
                    } catch (MessagingException e) {
                        return false;
                    }
                })
                .max(Comparator.comparing(m -> {
                    try {
                        return m.getSentDate();
                    } catch (MessagingException e) {
                        return new Date(0);
                    }
                }))
                .orElse(null);

        if (latestMessage != null) {
            EmailData email = emailService.parseEmail(latestMessage);


            System.out.println("From: " + email.from());
            System.out.println("Subject: " + email.subject());
            System.out.println("Body: " + email.body());

            emailService.sendDummyReply(
                    "hyc018018@gmail.com",
                    email.subject()
            );
        }

        session.closeSession();
    }

    @Test
    void printAllMessagesTest() throws Exception {

        EmailSession session = emailService.readUnreadEmails();
        List<Message> messages = session.getMessages();

        System.out.println("Unread message count: " + messages.size());

        for (Message message : messages) {
            System.out.println("=================================");
            System.out.println("From: " + Arrays.toString(message.getFrom()));
            System.out.println("Subject: " + message.getSubject());
            System.out.println("Date: " + message.getSentDate());
            System.out.println("=================================");
        }

        Message latestMessage = messages.stream()
                .filter(m -> {
                    try {
                        return m.getSentDate() != null;
                    } catch (MessagingException e) {
                        return false;
                    }
                })
                .max(Comparator.comparing(m -> {
                    try {
                        return m.getSentDate();
                    } catch (MessagingException e) {
                        return new Date(0);
                    }
                }))
                .orElseThrow();

        EmailData email = emailService.parseEmail(latestMessage);

        System.out.println("\nLATEST UNREAD MESSAGE");
        System.out.println("From: " + email.from());
        System.out.println("Subject: " + email.subject());
        System.out.println("Body: " + email.body());

        session.closeSession();
    }

}
