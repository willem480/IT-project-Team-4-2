package org.example.ticketing_app.service.impl;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.TicketAssignment;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.mapper.UserMapper;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

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
public class TicketAssignmentServiceImpl extends ServiceImpl<TicketAssignmentMapper, TicketAssignment> {
    private final TicketMapper ticketMapper;
    private final UserMapper userMapper;
    public List<TicketAssignmentReturn> getTicketAssignmentByAssigneeID(Integer userID) {
        List<TicketAssignment> ticketAssignments = lambdaQuery().eq(TicketAssignment:: getAssigneeId, userID).list();
        List<TicketAssignmentReturn> ticketAssignmentReturns = new ArrayList<TicketAssignmentReturn>();
        for (TicketAssignment ticketAssignment : ticketAssignments) {
            TicketAssignmentReturn ticketAssignmentReturn = new TicketAssignmentReturn();
            Ticket ticket = ticketMapper.selectById(ticketAssignment.getTicketId());
            User assignee = userMapper.selectById(ticketAssignment.getAssigneeId());
            User poster = userMapper.selectById(ticket.getPosterId());

            ticketAssignmentReturn.setPosterID(poster.getIdUser());
            ticketAssignmentReturn.setPosterName(poster.getName());
            ticketAssignmentReturn.setAssigneeID(assignee.getIdUser());
            ticketAssignmentReturn.setAssigneeName(assignee.getName());
            ticketAssignmentReturn.setTitle(ticket.getTitle());
            ticketAssignmentReturn.setDescription(ticket.getDescription());
            ticketAssignmentReturn.setDatePosted(ticket.getDatePosted());
            ticketAssignmentReturn.setDateAssigned(ticketAssignment.getDateAssigned());
            ticketAssignmentReturn.setPay(ticket.getPay());
            ticketAssignmentReturn.setEmail(ticket.getEmail());
            ticketAssignmentReturn.setLocation(ticket.getLocation());
            ticketAssignmentReturn.setStatus(ticket.getStatus());
            ticketAssignmentReturns.add(ticketAssignmentReturn);
        }
        return ticketAssignmentReturns;
    }


}
