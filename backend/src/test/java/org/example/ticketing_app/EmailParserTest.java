package org.example.ticketing_app;

import jakarta.mail.Message;
import jakarta.mail.Part;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeBodyPart;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.emailServiceHelper.EmailServiceHelper;
import org.junit.jupiter.api.Test;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;

class EmailParserTest {

    @Test
    void parsesPlainTextHeadersAndMessageId() throws Exception {
        MimeMessage message = newMessage();
        message.setFrom("sender@example.com");
        message.setRecipients(Message.RecipientType.TO, "service@example.com");
        message.setSubject("Broken light");
        message.setText("The hallway light is broken.");
        message.saveChanges();
        message.setHeader("Message-ID", "<message-1@example.com>");

        EmailData email = EmailServiceHelper.parseEmail(message);

        assertEquals("sender@example.com", email.getFrom());
        assertEquals("service@example.com", email.getTo());
        assertEquals("Broken light", email.getSubject());
        assertEquals("<message-1@example.com>", email.getMessageId());
        assertEquals("The hallway light is broken.", email.getBody());
    }

    @Test
    void prefersPlainTextAndExcludesAttachments() throws Exception {
        MimeMessage message = newMessage();
        MimeMultipart alternative = new MimeMultipart("alternative");
        alternative.addBodyPart(textPart("Plain text version", "text/plain; charset=UTF-8"));
        alternative.addBodyPart(textPart("<p>HTML version</p>", "text/html; charset=UTF-8"));

        MimeBodyPart content = new MimeBodyPart();
        content.setContent(alternative);

        MimeBodyPart attachment = textPart("Attachment content must not be parsed", "text/plain; charset=UTF-8");
        attachment.setDisposition(Part.ATTACHMENT);
        attachment.setFileName("details.txt");

        MimeMultipart mixed = new MimeMultipart("mixed");
        mixed.addBodyPart(content);
        mixed.addBodyPart(attachment);
        message.setContent(mixed);
        message.saveChanges();

        assertEquals("Plain text version", EmailServiceHelper.parseEmail(message).getBody());
    }

    @Test
    void usesHtmlTextWhenPlainTextIsUnavailable() throws Exception {
        MimeMessage message = newMessage();
        message.setContent("<p>Air conditioner <strong>not working</strong>.</p>", "text/html; charset=UTF-8");
        message.saveChanges();

        assertEquals("Air conditioner not working.", EmailServiceHelper.parseEmail(message).getBody());
    }

    private MimeMessage newMessage() {
        return new MimeMessage(Session.getInstance(new Properties()));
    }

    private MimeBodyPart textPart(String content, String contentType) throws Exception {
        MimeBodyPart part = new MimeBodyPart();
        part.setContent(content, contentType);
        return part;
    }
}
