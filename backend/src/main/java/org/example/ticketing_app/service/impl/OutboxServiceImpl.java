package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import org.example.ticketing_app.entity.Inbox;
import org.example.ticketing_app.entity.Outbox;
import org.example.ticketing_app.mapper.InboxMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.OutboxMapper;
import org.example.ticketing_app.service.emailServiceHelper.*;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;

import static org.example.ticketing_app.service.emailServiceHelper.EmailServiceHelper.createImapStore;
import static org.example.ticketing_app.service.emailServiceHelper.EmailServiceHelper.extractBody;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
public class OutboxServiceImpl extends ServiceImpl<OutboxMapper, Outbox> {

//    @Scheduled(fixedRate = 3000)
//    public void syncOutbox() throws Exception {
//
//        Store store =
//                EmailServiceHelper.createImapStore();
//
//        Folder sentFolder =
//                store.getFolder("INBOX.Sent");
//
//        sentFolder.open(Folder.READ_ONLY);
//
//        Message[] messages =
//                sentFolder.getMessages();
//
//        for (Message message : messages) {
//
//            EmailData emailData =
//                    EmailServiceHelper.parseEmail(message);
//
//            boolean exists =
//                    baseMapper.exists(
//                            new LambdaQueryWrapper<Outbox>()
//                                    .eq(
//                                            Outbox::getIdEmail,
//                                            emailData.getMessageId()
//                                    )
//                    );
//
//            if (exists) {
//                continue;
//            }
//
//            Outbox outbox = new Outbox();
//
//            outbox.setIdEmail(emailData.getMessageId());
//
//            outbox.setDateReceived(
//                    new Timestamp(
//                            message.getReceivedDate().getTime()
//                    ).toLocalDateTime()
//            );
//
//            outbox.setDateSent(
//                    new Timestamp(
//                            message.getSentDate().getTime()
//                    ).toLocalDateTime()
//            );
//
//            outbox.setSender(
//                    emailData.getFrom()
//            );
//
//            outbox.setReceiver(emailData.getTo());
//
//            outbox.setSubject(
//                    emailData.getSubject()
//            );
//
//            outbox.setBody(
//                    emailData.getBody()
//            );
//
//            outbox.setStatus(EmailServiceHelper.getStatus(message));
//
//            baseMapper.insert(outbox);
//        }
//
//        sentFolder.close(false);
//        store.close();
//    }
}
