package org.example.ticketing_app.service.impl;

import jakarta.mail.*;
import org.example.ticketing_app.entity.Inbox;
import org.example.ticketing_app.mapper.InboxMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.LocalDateTime;


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

    private final TicketServiceImpl ticketService;

    public InboxServiceImpl(TicketServiceImpl ticketService) {
        this.ticketService = ticketService;
    }

    @Scheduled(fixedRate = 3000)
    @Transactional
    public void syncInbox() throws Exception {

        Store store = EmailServiceHelper.createImapStore();

        Folder inboxFolder = store.getFolder("INBOX");

        inboxFolder.open(Folder.READ_ONLY);

        Message[] messages = inboxFolder.getMessages();

        for (Message message : messages) {

            EmailData emailData =
                    EmailServiceHelper.parseEmail(message);

            Inbox inbox =
                    getById(emailData.getMessageId());

            boolean isNewEmail = inbox == null;

            if (isNewEmail) {
                inbox = new Inbox();
                inbox.setIdEmail(emailData.getMessageId());
            }

            inbox.setDateReceived(
                    new Timestamp(
                            message.getReceivedDate().getTime()
                    ).toLocalDateTime()
            );

            LocalDateTime dateSent = message.getSentDate() == null
                    ? LocalDateTime.now()
                    : new Timestamp(message.getSentDate().getTime()).toLocalDateTime();

            inbox.setDateSent(dateSent);

            inbox.setSender(
                    emailData.getFrom()
            );

            inbox.setReceiver(
                    emailData.getTo()
            );

            inbox.setSubject(
                    emailData.getSubject()
            );

            inbox.setBody(
                    emailData.getBody()
            );
            inbox.setStatus(EmailServiceHelper.getStatus(message));

            saveOrUpdate(inbox);

            if (isNewEmail) {
                ticketService.createTicketFromEmail(emailData, dateSent);
            }
        }

        inboxFolder.close(false);
        store.close();
        System.out.println("Inbox sync complete.");
    }
}
