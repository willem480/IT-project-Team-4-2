package org.example.ticketing_app.service.emailService;

import jakarta.mail.Folder;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.Store;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Builder
@Getter
@Setter
/**
 * An email session that from an IMAP connection
 */
public class EmailSession {
    /**
     * messages retrieved from the session, this list is tightly bound to this session and will not
     * be valid after the session is closed
     */
    List<Message> messages;
    Folder folder;
    Store store;

    /**
     * closes an email session
     * @throws MessagingException
     */
    public void closeSession() throws MessagingException {
        if (folder != null && folder.isOpen()) {
            folder.close(false);
        }
        if (store != null && store.isConnected()) {
            store.close();
        }
    }
}
