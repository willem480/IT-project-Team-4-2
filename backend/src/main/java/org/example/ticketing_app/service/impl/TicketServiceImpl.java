package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
public class TicketServiceImpl extends ServiceImpl<TicketMapper, Ticket> {

    private final UserServiceImpl userService;

    public TicketServiceImpl(UserServiceImpl userService) {
        this.userService = userService;
    }
    public String getAllTickets() {
        return "get all tickets is working";
    }

    public String getTicketById(Long id) {
        return "Ticket " + id;
    }

    @Transactional
    public Ticket createTicketFromEmail(EmailData emailData, LocalDateTime datePosted) {
        Ticket existingTicket = getOne(
                new LambdaQueryWrapper<Ticket>()
                        .eq(Ticket::getSourceEmailId, emailData.getMessageId()),
                false
        );

        if (existingTicket != null) {
            return existingTicket;
        }

        User user = findOrCreateUser(emailData.getFrom());

        Ticket ticket = new Ticket();
        ticket.setUserId(user.getIdUser());
        ticket.setTitle(emailData.getSubject());
        ticket.setDescription(emailData.getBody());
        ticket.setDatePosted(datePosted);
        ticket.setEmail(emailData.getFrom());
        ticket.setSourceEmailId(emailData.getMessageId());
        save(ticket);
        return ticket;
    }

    private User findOrCreateUser(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Incoming email must include a sender address");
        }

        User existingUser = userService.getOne(
                new LambdaQueryWrapper<User>().eq(User::getEmail, email),
                false
        );

        if (existingUser != null) {
            return existingUser;
        }

        User user = new User();
        int atIndex = email.indexOf('@');
        user.setName(atIndex > 0 ? email.substring(0, atIndex) : email);
        user.setEmail(email);
        userService.save(user);
        return user;
    }
}
