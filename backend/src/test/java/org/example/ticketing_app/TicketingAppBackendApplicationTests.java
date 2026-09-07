package org.example.ticketing_app;

import jakarta.mail.Message;
import org.example.ticketing_app.service.emailService.EmailData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.example.ticketing_app.service.emailService.*;
import java.util.List;
@SpringBootTest
class TicketingAppBackendApplicationTests {
    @Autowired
    EmailService emailService;
    @Test
    void sendAndReceiveEmail() throws Exception {

            List<Message> messages = emailService.readUnreadEmails();

        EmailData email = emailService.parseEmail(messages.getFirst());

        System.out.println("From: " + email.from());
        System.out.println("Subject: " + email.subject());
        System.out.println("Body: " + email.body());

        emailService.sendDummyReply(
                "hyc018018@gmail.com",
                email.subject()
        );
    }

}
