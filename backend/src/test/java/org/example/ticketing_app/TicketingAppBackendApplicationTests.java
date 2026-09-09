package org.example.ticketing_app;

import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.impl.InboxServiceImpl;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.example.ticketing_app.service.emailServiceHelper.*;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

@SpringBootTest
class TicketingAppBackendApplicationTests {
    @Autowired
    InboxServiceImpl inboxService;
    @Test
    void sendAndReceiveEmail() throws Exception {

        EmailSession session = inboxService.readUnreadEmails();
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
            EmailData email = inboxService.parseEmail(latestMessage);


            System.out.println("From: " + email.from());
            System.out.println("Subject: " + email.subject());
            System.out.println("Body: " + email.body());

            inboxService.sendDummyReply(
                    "hyc018018@gmail.com",
                    email.subject()
            );
        }

        session.closeSession();
    }

    @Test
    void printAllMessagesTest() throws Exception {

        EmailSession session = inboxService.readUnreadEmails();
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

        EmailData email = inboxService.parseEmail(latestMessage);

        System.out.println("\nLATEST UNREAD MESSAGE");
        System.out.println("From: " + email.from());
        System.out.println("Subject: " + email.subject());
        System.out.println("Body: " + email.body());

        session.closeSession();
    }

}
