package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.TicketComment;
import org.example.ticketing_app.mapper.TicketCommentMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-27
 */
@Service
public class TicketCommentServiceImpl extends ServiceImpl<TicketCommentMapper, TicketComment> {
    @Transactional
    public void postComment(int userID, int ticketID, String content) {
        TicketComment comment = new TicketComment();
        comment.setContent(content);
        comment.setDate(LocalDateTime.now());
        comment.setTicketIdticket(ticketID);
        comment.setUserIduser(userID);
        save(comment);
    }

    public List<TicketComment> getTicketCommentByTicketID(int ticketID) {
        return lambdaQuery().eq(TicketComment::getTicketIdticket, ticketID).list();
    }
}
