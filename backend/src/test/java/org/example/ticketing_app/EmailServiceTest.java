package org.example.ticketing_app;

import jakarta.mail.Folder;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.Store;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.impl.InboxServiceImpl;
import org.example.ticketing_app.service.impl.OutboxServiceImpl;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.example.ticketing_app.service.emailServiceHelper.*;

import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

@SpringBootTest
class EmailServiceTest {
    public String imapHost;
    public int imapPort;
    public String imapUsername;
    public String imapPassword;
    public String smtpHost;
    public int smtpPort;
    public String smtpUsername;
    public String smtpPassword;

    @Value("${email.imap.host}")
    public void setImapHost(String value) {
        imapHost = value;
    }

    @Value("${email.imap.port}")
    public void setImapPort(int value) {
        imapPort = value;
    }

    @Value("${email.imap.username}")
    public void setImapUsername(String value) {
        imapUsername = value;
    }

    @Value("${email.imap.password}")
    public void setImapPassword(String value) {
        imapPassword = value;
    }

    @Value("${email.smtp.host}")
    public void setSmtpHost(String value) {
        smtpHost = value;
    }

    @Value("${email.smtp.port}")
    public void setSmtpPort(int value) {
        smtpPort = value;
    }

    @Value("${email.smtp.username}")
    public void setSmtpUsername(String value) {
        smtpUsername = value;
    }

    @Value("${email.smtp.password}")
    public void setSmtpPassword(String value) {
        smtpPassword = value;
    }

    @Autowired
    InboxServiceImpl inboxService;

    @Test
    void sendAndReceiveEmail() throws Exception {
        EmailSession session = EmailServiceHelper.readUnreadEmails(imapHost, imapPort, imapUsername, imapPassword);
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
            EmailData email = EmailServiceHelper.parseEmail(latestMessage);


            System.out.println("From: " + email.getFrom());
            System.out.println("Subject: " + email.getSubject());
            System.out.println("Body: " + email.getBody());

            EmailServiceHelper.sendDummyReply(
                    smtpHost, smtpPort, smtpUsername, smtpPassword, "hyc018018@163.com", email.getSubject()
            );
        }
        else {
            System.out.println("No messages found");
        }
        session.closeSession();
    }

    @Test
    void printAllMessagesTest() throws Exception {

        EmailSession session = EmailServiceHelper.readUnreadEmails(imapHost, imapPort, imapUsername, imapPassword);
        List<Message> messages = session.getMessages();

        System.out.println("Unread message count: " + messages.size());

        if (!messages.isEmpty()) {
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

            EmailData email = EmailServiceHelper.parseEmail(latestMessage);

            System.out.println("\nLATEST UNREAD MESSAGE");
            System.out.println("From: " + email.getFrom());
            System.out.println("Subject: " + email.getSubject());
            System.out.println("Body: " + email.getBody());
        }

        session.closeSession();
    }

    @Test
    void emailSyncTest() throws Exception {
        Store store = EmailServiceHelper.createImapStore();

        for (Folder folder : store.getDefaultFolder().list("*")) {

            folder.open(Folder.READ_ONLY);

            System.out.println(
                    folder.getFullName() +
                            " -> " +
                            folder.getMessageCount()
            );

            folder.close(false);
        }
        inboxService.syncInbox();
    }
}
