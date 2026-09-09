package org.example.ticketing_app.service.impl;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.search.FlagTerm;
import org.example.ticketing_app.entity.Inbox;
import org.example.ticketing_app.mapper.InboxMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.emailServiceHelper.EmailSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Properties;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
public class InboxServiceImpl extends ServiceImpl<InboxMapper, Inbox> {
    @Value("${email.imap.host}")
    private String imapHost;

    @Value("${email.imap.port}")
    private int imapPort;

    @Value("${email.imap.username}")
    private String imapUsername;

    @Value("${email.imap.password}")
    private String imapPassword;

    @Value("${email.smtp.host}")
    private String smtpHost;

    @Value("${email.smtp.port}")
    private int smtpPort;

    @Value("${email.smtp.username}")
    private String smtpUsername;

    @Value("${email.smtp.password}")
    private String smtpPassword;

    /**
     * reads the unseen messages in the inbox and returns them
     * @return an email session that contains the messages,
     * you need to call CloseSession after you are done with the messages
     */
    public EmailSession readUnreadEmails() throws Exception {

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

    /**
     * mark the messages in an email session with a flag
     * @param emailSession
     * @param flag
     * @param value
     * @throws MessagingException
     */
    private void markMessages(EmailSession emailSession, Flags.Flag flag, boolean value)
            throws MessagingException {
        List<Message> messages = emailSession.getMessages();
        for (Message message : messages) {
            message.setFlag(flag, value);
        }
    }

    public EmailData parseEmail(
            Message message
    ) throws Exception {
        String from =
                ((InternetAddress) message.getFrom()[0])
                        .getAddress();

        String subject = message.getSubject();

        String messageId = "";

        String[] ids =
                message.getHeader("Message-ID");

        if (ids != null && ids.length > 0) {
            messageId = ids[0];
        }

        String body = extractBody(message);

        return new EmailData(
                messageId,
                from,
                subject,
                body
        );
    }

    private String extractBody(
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

    public void sendDummyReply(
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
                new InternetAddress(smtpUsername)
        );

        reply.setRecipients(
                Message.RecipientType.TO,
                InternetAddress.parse(recipient)
        );

        reply.setSubject(
                "Re: " + originalSubject
        );

        reply.setText("Automated test reply.");

        Transport.send(reply);
    }
}
