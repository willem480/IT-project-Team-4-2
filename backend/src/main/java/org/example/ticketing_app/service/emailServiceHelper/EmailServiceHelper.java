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
            return "SEEN";
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

        if (message == null) {
            throw new IllegalArgumentException("message must not be null");
        }

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
                subject == null ? "" : subject,
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

        return extractBodyContent(part).preferredText();
    }

    private static BodyContent extractBodyContent(Part part) throws Exception {
        if (Part.ATTACHMENT.equalsIgnoreCase(part.getDisposition())
                || part.getFileName() != null) {
            return BodyContent.empty();
        }

        if (part.isMimeType("text/plain")) {
            return new BodyContent(textContent(part), "");
        }

        if (part.isMimeType("text/html")) {
            return new BodyContent("", htmlToText(textContent(part)));
        }

        if (!part.isMimeType("multipart/*")) {
            return BodyContent.empty();
        }

        Multipart multipart = (Multipart) part.getContent();
        StringBuilder plainText = new StringBuilder();
        StringBuilder htmlText = new StringBuilder();

        for (int i = 0; i < multipart.getCount(); i++) {
            BodyContent content = extractBodyContent(multipart.getBodyPart(i));
            appendText(plainText, content.plainText());
            appendText(htmlText, content.htmlText());
        }

        return new BodyContent(plainText.toString(), htmlText.toString());
    }

    private static String textContent(Part part) throws Exception {
        Object content = part.getContent();
        return content instanceof String text ? text.trim() : "";
    }

    private static String htmlToText(String html) {
        return html
                .replaceAll("(?is)<(script|style)[^>]*>.*?</\\1>", " ")
                .replaceAll("(?i)<br\\s*/?>", "\n")
                .replaceAll("(?i)</p>|</div>|</li>", "\n")
                .replaceAll("<[^>]+>", " ")
                .replace("&nbsp;", " ")
                .replaceAll("[ \\t]+", " ")
                .replaceAll("\\n{3,}", "\n\n")
                .replaceAll("\\s+([.,;:!?])", "$1")
                .trim();
    }

    private static void appendText(StringBuilder target, String text) {
        if (text.isBlank()) {
            return;
        }

        if (!target.isEmpty()) {
            target.append('\n');
        }

        target.append(text);
    }

    private record BodyContent(String plainText, String htmlText) {
        private static BodyContent empty() {
            return new BodyContent("", "");
        }

        private String preferredText() {
            return plainText.isBlank() ? htmlText : plainText;
        }
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
