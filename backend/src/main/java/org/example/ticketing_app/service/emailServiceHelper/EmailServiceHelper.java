package org.example.ticketing_app.service.emailServiceHelper;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.search.FlagTerm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Properties;

@Service
public final class EmailServiceHelper {

    public static String imapHost;
    public static int imapPort;
    public static String imapUsername;
    public static String imapPassword;
    public static String smtpHost;
    public static int smtpPort;
    public static String smtpUsername;
    public static String smtpPassword;

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

    public static String getStatus(
            Message message
    ) throws MessagingException {

        Flags flags = message.getFlags();

        if (flags.contains(Flags.Flag.DELETED)) {
            return "DELETED";
        }

        if (flags.contains(Flags.Flag.ANSWERED)) {
            return "ANSWERED";
        }

        if (flags.contains(Flags.Flag.DRAFT)) {
            return "DRAFT";
        }

        if (flags.contains(Flags.Flag.FLAGGED)) {
            return "FLAGGED";
        }

        if (flags.contains(Flags.Flag.SEEN)) {
            return "READ";
        }

        return "UNREAD";
    }

    public static Store createImapStore() throws Exception {

        Properties props = new Properties();

        props.put("mail.store.protocol", "imaps");
        props.put("mail.imaps.host", imapHost);
        props.put("mail.imaps.port", String.valueOf(imapPort));
        props.put("mail.imaps.ssl.enable", "true");

        Session session = Session.getInstance(props);

        Store store = session.getStore("imaps");

        store.connect(
                imapHost,
                imapUsername,
                imapPassword
        );

        return store;
    }

    public static EmailSession readUnreadEmails(
            String imapHost,
            int imapPort,
            String imapUsername,
            String imapPassword
    ) throws Exception {

        Store store = createImapStore();

        Folder inbox = store.getFolder("INBOX");

        inbox.open(Folder.READ_WRITE);

        Message[] messages = inbox.search(
                new FlagTerm(
                        new Flags(Flags.Flag.SEEN),
                        false
                )
        );

        return EmailSession.builder()
                .messages(Arrays.asList(messages))
                .folder(inbox)
                .store(store)
                .build();
    }

    public static void markMessages(
            EmailSession emailSession,
            Flags.Flag flag,
            boolean value
    ) throws MessagingException {

        List<Message> messages =
                emailSession.getMessages();

        for (Message message : messages) {
            message.setFlag(flag, value);
        }
    }

    public static EmailData parseEmail(
            Message message
    ) throws Exception {

        String from = concatAddresses(message.getFrom());
        String to = concatAddresses(message.getRecipients(Message.RecipientType.TO));
        String subject =
                message.getSubject();

        String messageId = "";

        String[] ids =
                message.getHeader("Message-ID");

        if (ids != null && ids.length > 0) {
            messageId = ids[0];
        }

        String body =
                extractBody(message);

        return new EmailData(
                messageId,
                from,
                to,
                subject,
                body
        );
    }

    public static String concatAddresses(Address[] addresses) throws MessagingException {
        String result = "";

        if (addresses != null) {

            StringBuilder builder =
                    new StringBuilder();

            for (Address address : addresses) {

                if (address instanceof InternetAddress internetAddress) {

                    if (!builder.isEmpty()) {
                        builder.append(",");
                    }

                    builder.append(
                            internetAddress.getAddress()
                    );
                }
            }

            result = builder.toString();
        }
        return result;
    }

    public static String extractBody(
            Part part
    ) throws Exception {

        if (part.isMimeType("text/plain")) {
            return (String) part.getContent();
        }

        if (part.isMimeType("text/html")) {

            String html =
                    (String) part.getContent();

            return html
                    .replaceAll("<[^>]+>", " ")
                    .replace("&nbsp;", " ")
                    .trim();
        }

        if (part.isMimeType("multipart/*")) {

            Multipart multipart =
                    (Multipart) part.getContent();

            StringBuilder body =
                    new StringBuilder();

            for (int i = 0; i < multipart.getCount(); i++) {

                body.append(
                        extractBody(
                                multipart.getBodyPart(i)
                        )
                );
            }

            return body.toString();
        }

        return "";
    }

    public static void sendDummyReply(
            String smtpHost,
            int smtpPort,
            String smtpUsername,
            String smtpPassword,
            String recipient,
            String originalSubject
    ) throws Exception {

        Properties props = new Properties();

        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", String.valueOf(smtpPort));
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.ssl.enable", "true");

        Session session = Session.getInstance(
                props,
                new Authenticator() {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(
                                smtpUsername,
                                smtpPassword
                        );
                    }
                }
        );

        MimeMessage reply =
                new MimeMessage(session);

        reply.setFrom(
                new InternetAddress(
                        smtpUsername
                )
        );

        reply.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(
                        recipient
                )
        );

        reply.setSubject(
                "Re: " + originalSubject
        );

        reply.setText(
                "Automated test reply."
        );

        Transport.send(reply);
    }
}