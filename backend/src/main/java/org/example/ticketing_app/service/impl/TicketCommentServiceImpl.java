package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.TicketComment;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketCommentMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.ticketServiceHelper.TicketCommentReturn;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
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
    private final TicketMapper ticketMapper;
    private final UserMapper userMapper;

    public TicketCommentServiceImpl(TicketMapper ticketMapper, UserMapper userMapper) {
        this.ticketMapper = ticketMapper;
        this.userMapper = userMapper;
    }

    @Transactional
    public void postComment(int operatorId, int ticketID, String content) {
        TicketComment comment = new TicketComment();
        comment.setContent(content);
        comment.setDate(LocalDateTime.now());
        comment.setTicketIdticket(ticketID);
        comment.setUserIduser(operatorId);
        save(comment);
        Ticket ticket = ticketMapper.selectById(ticketID);
        if (ticket != null) {
            User ticketPoster = userMapper.selectById(ticket.getPosterId());
            if ((ticketPoster != null) && (ticketPoster.getIdUser() != operatorId) && (ticketPoster.getSubscribeEmail() == 1)) {
                ///send email here
            }
        }
    }

    public List<TicketCommentReturn> getTicketCommentByTicketID(int operatorId, int ticketID) {

        List<TicketComment> ticketComments = lambdaQuery().eq(TicketComment::getTicketIdticket, ticketID).list();
        List<TicketCommentReturn> ticketCommentReturns = new ArrayList<>();
        for (TicketComment ticketComment : ticketComments) {
            User poster = userMapper.selectById(ticketComment.getUserIduser());
            TicketCommentReturn ticketCommentReturn = new TicketCommentReturn();
            ticketCommentReturn.setIdticketComment(ticketComment.getIdticketComment());
            ticketCommentReturn.setDate(ticketComment.getDate());
            ticketCommentReturn.setTicketId(ticketComment.getTicketIdticket());
            ticketCommentReturn.setContent(ticketComment.getContent());
            ticketCommentReturn.setPosterId(poster.getIdUser());
            ticketCommentReturn.setUserName(poster.getName());
            ticketCommentReturn.setOwnedByCurUser(poster.getIdUser() == operatorId);
            ticketCommentReturns.add(ticketCommentReturn);
        }
        return ticketCommentReturns;
    }

    public boolean deleteTicketComment(int operatorId, int ticketCommentId) {
        TicketComment comment = baseMapper.selectById(ticketCommentId);
        if (comment == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ticket comment not found for this id");
        if (comment.getUserIduser() == operatorId) {
            baseMapper.deleteById(ticketCommentId);
            return true;
        }
        else{
            return false;
        }
    }
}
