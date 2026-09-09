package org.example.ticketing_app.service.impl;

import jakarta.mail.*;
import org.example.ticketing_app.entity.Inbox;
import org.example.ticketing_app.mapper.InboxMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;


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

    @Scheduled(fixedRate = 3000)
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

            if (inbox == null) {
                inbox = new Inbox();
                inbox.setIdEmail(emailData.getMessageId());
            }

            inbox.setDateReceived(
                    new Timestamp(
                            message.getReceivedDate().getTime()
                    ).toLocalDateTime()
            );

            inbox.setDateSent(
                    new Timestamp(
                            message.getSentDate().getTime()
                    ).toLocalDateTime()
            );

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
        }

        inboxFolder.close(false);
        store.close();
        System.out.println("Inbox sync complete.");
    }
}
