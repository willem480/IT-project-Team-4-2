package org.example.ticketing_app.service.impl;

import jakarta.mail.*;
import jakarta.mail.search.FlagTerm;
import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Inbox;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.mapper.InboxMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.*;
import org.springframework.beans.factory.annotation.Autowired;
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
@RequiredArgsConstructor
public class InboxServiceImpl extends ServiceImpl<InboxMapper, Inbox> {

    private final TicketServiceImpl ticketService;

    @Scheduled(fixedRate = 3000)
    @Transactional(rollbackFor = Exception.class)
    public void syncInbox() throws Exception {

        Store store = EmailServiceHelper.createImapStore();

        Folder inboxFolder = store.getFolder("INBOX");

        inboxFolder.open(Folder.READ_WRITE);

        // Process only unread messages so completed emails are never replied to again.
        Message[] messages = inboxFolder.search(
                new FlagTerm(new Flags(Flags.Flag.SEEN), false)
        );

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


                if (ticketService.isStatusRequest(emailData)) {

                    EmailServiceHelper.sendStatusSummaryReply(
                            emailData.getFrom(),
                            ticketService.getTicketsByEmail(emailData.getFrom())
                    );

                } else if (ticketService.isValidPostJobEmail(emailData)) {

                    Ticket createdTicket = ticketService.createTicketFromEmail(
                            emailData,
                            dateSent
                    );

                    // Only a successfully created ticket receives a confirmation email.
                    if (createdTicket != null) {
                        EmailServiceHelper.sendTicketCreatedReply(
                                emailData.getFrom(),
                                emailData.getSubject(),
                                createdTicket
                        );
                    }

                } else if (ticketService.isUpdateTicketEmail(emailData)) {

                    Ticket updatedTicket = ticketService.updateTicketFromEmail(emailData);
                    if (updatedTicket != null) {
                        EmailServiceHelper.sendTicketUpdatedReply(
                                emailData.getFrom(),
                                emailData.getSubject(),
                                updatedTicket
                        );
                    } else {
                        EmailServiceHelper.sendTicketUpdateFailureReply(
                                emailData.getFrom(),
                                emailData.getSubject()
                        );
                    }

                } else {

                    EmailServiceHelper.sendInvalidFormatReply(
                            emailData.getFrom(),
                            emailData.getSubject()
                    );
                }
            }

            // Mark the source email as read only after all processing and replies succeed.
            message.setFlag(Flags.Flag.SEEN, true);
            inbox.setStatus(EmailServiceHelper.getStatus(message));
            saveOrUpdate(inbox);
        }

        inboxFolder.close(false);
        store.close();
        System.out.println("Inbox sync complete.");
    }
}
