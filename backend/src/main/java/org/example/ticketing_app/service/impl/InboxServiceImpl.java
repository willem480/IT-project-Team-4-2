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

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.entity.TicketAssignment;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.example.ticketing_app.service.emailServiceHelper.EmailSummary;

import java.util.List;

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
    private final UserServiceImpl userService;
    private final TicketAssignmentMapper ticketAssignmentMapper;
    private final TicketMapper ticketMapper;

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

            String replyRecipient =
                    EmailServiceHelper.getSingleSender(message);

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


                if (ticketService.isSummaryRequest(emailData)) {

                    EmailServiceHelper.sendStatusSummaryReply (
                        replyRecipient, buildEmailSummary(replyRecipient)
                    );
                } else if (ticketService.isValidPostJobEmail(emailData)) {

                    Ticket createdTicket = ticketService.createTicketFromEmail(
                            emailData,
                            dateSent
                    );

                    // Only a successfully created ticket receives a confirmation email.
                    if (createdTicket != null) {
                        EmailServiceHelper.sendTicketCreatedReply(
                                replyRecipient,
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

                } else if (ticketService.isCancelTicketEmail(emailData)) {

                    Ticket deletedTicket = ticketService.deleteTicketFromEmail(emailData);
                    if (deletedTicket != null) {
                        EmailServiceHelper.sendTicketDeletedReply(
                                emailData.getFrom(),
                                emailData.getSubject(),
                                deletedTicket
                            );
                    } else {
                        EmailServiceHelper.sendTicketCancellationFailureReply(
                                emailData.getFrom(),
                                emailData.getSubject()
                        );
                    }

                } else {

                    EmailServiceHelper.sendInvalidFormatReply(
                            replyRecipient,
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
    }

    private EmailSummary buildEmailSummary(String email) {

        EmailSummary summary = new EmailSummary();

        // Find user by email
        User user = userService.lambdaQuery()
                .eq(User::getEmail, email)
                .one();

        summary.setUser(user);

        // Tickets posted by this email
        List<Ticket> postedTickets =
                ticketService.getTicketsByEmail(email);

        summary.setPostedTickets(postedTickets);

        // If this email does not belong to a registered user,
        // there cannot be user assignment statistics.
        if (user == null) {
            return summary;
        }

        List<TicketAssignment> assignments =
                ticketAssignmentMapper.selectList(
                        new LambdaQueryWrapper<TicketAssignment>()
                                .eq(
                                        TicketAssignment::getAssigneeId,
                                        user.getIdUser()
                                )
                );

        int completed = 0;
        int inProgress = 0;
        int earnings = 0;

        for (TicketAssignment assignment : assignments) {

            Ticket ticket =
                    ticketMapper.selectById(
                            assignment.getTicketId()
                    );

            if (ticket == null) {
                continue;
            }

            if (TicketStatus.CLOSED.name()
                    .equals(ticket.getStatus())) {

                completed++;

                if (ticket.getPay() != null) {
                    earnings += ticket.getPay();
                }

            } else if (TicketStatus.IN_PROGRESS.name()
                    .equals(ticket.getStatus())) {

                inProgress++;
            }
        }

        summary.setTotalAssignedJobs(assignments.size());
        summary.setCompletedJobs(completed);
        summary.setInProgressJobs(inProgress);
        summary.setTotalEarnings(earnings);

        return summary;
    }
}
