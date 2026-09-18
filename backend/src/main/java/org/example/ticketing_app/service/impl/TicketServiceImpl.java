package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.ticketServiceHelper.CreateTicketRequest;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

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

    /** Only emails with this phrase in the subject are treated as job postings. */
    private static final String POST_JOB_SUBJECT_MARKER = "post job";

    /** Each expression reads one required field from the agreed email body template. */
    private static final Pattern TITLE_PATTERN = Pattern.compile(
            "(?im)^\\s*Title\\s*:\\s*(.+?)\\s*$"
    );
    private static final Pattern DESCRIPTION_PATTERN = Pattern.compile(
            "(?ims)^\\s*Description\\s*:\\s*(.*?)(?=^\\s*(?:Location|Pay)\\s*:|\\z)"
    );
    private static final Pattern LOCATION_PATTERN = Pattern.compile(
            "(?im)^\\s*Location\\s*:\\s*(.+?)\\s*$"
    );
    private static final Pattern PAY_PATTERN = Pattern.compile(
            "(?im)^\\s*Pay\\s*:\\s*\\$?\\s*(\\d+)\\s*$"
    );

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

    /**
     * Creates a ticket submitted manually from the app.
     * The server owns the posting time, poster email, and initial ticket status.
     */
    @Transactional
    public Ticket createTicket(CreateTicketRequest request) {
        User poster = userService.getById(request.getPosterId());
        if (poster == null) {
            throw new ResponseStatusException(NOT_FOUND, "Poster does not exist");
        }
        if (poster.getEmail() == null || poster.getEmail().isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Poster must have an email address");
        }

        Ticket ticket = new Ticket();
        ticket.setPosterId(poster.getIdUser());
        ticket.setTitle(request.getTitle().trim());
        ticket.setDescription(request.getDescription().trim());
        ticket.setLocation(request.getLocation().trim());
        ticket.setPay(request.getPay());
        ticket.setEmail(poster.getEmail());
        ticket.setDatePosted(LocalDateTime.now());
        ticket.setStatus(TicketStatus.OPEN.name());
        save(ticket);
        return ticket;
    }

    @Transactional
    public Ticket createTicketFromEmail(EmailData emailData, LocalDateTime datePosted) {
        // Keep non-job emails in inbox only; they must not create a ticket.
        if (!isPostJobEmail(emailData) || emailData.getFrom() == null || emailData.getFrom().isBlank()) {
            return null;
        }

        // A malformed job-posting email remains in inbox but does not create a partial ticket.
        Optional<JobPosting> jobPosting = parseJobPosting(emailData.getBody());
        if (jobPosting.isEmpty()) {
            return null;
        }

        User user = findOrCreateUser(emailData.getFrom());

        Ticket ticket = new Ticket();
        ticket.setPosterId(user.getIdUser());
        ticket.setTitle(jobPosting.get().title());
        ticket.setDescription(jobPosting.get().description());
        ticket.setDatePosted(datePosted);
        ticket.setLocation(jobPosting.get().location());
        ticket.setPay(jobPosting.get().pay());
        ticket.setEmail(emailData.getFrom());
        ticket.setStatus(TicketStatus.OPEN.name());
        save(ticket);
        return ticket;
    }

    private boolean isPostJobEmail(EmailData emailData) {
        return emailData != null
                && emailData.getSubject() != null
                && emailData.getSubject().toLowerCase(Locale.ROOT).contains(POST_JOB_SUBJECT_MARKER);
    }

    /**
     * Parses the agreed email template:
     * Title, Description, Location, and Pay are all required before a ticket is created.
     */
    private Optional<JobPosting> parseJobPosting(String body) {
        if (body == null || body.isBlank()) {
            return Optional.empty();
        }

        Optional<String> title = requiredValue(TITLE_PATTERN, body);
        Optional<String> description = requiredValue(DESCRIPTION_PATTERN, body);
        Optional<String> location = requiredValue(LOCATION_PATTERN, body);
        Optional<String> payText = requiredValue(PAY_PATTERN, body);

        if (title.isEmpty() || description.isEmpty() || location.isEmpty() || payText.isEmpty()) {
            return Optional.empty();
        }

        try {
            return Optional.of(new JobPosting(
                    title.get(),
                    description.get(),
                    location.get(),
                    Integer.parseInt(payText.get())
            ));
        } catch (NumberFormatException exception) {
            // Pay must fit the ticket.pay INT column.
            return Optional.empty();
        }
    }

    private Optional<String> requiredValue(Pattern pattern, String body) {
        Matcher matcher = pattern.matcher(body);
        if (!matcher.find()) {
            return Optional.empty();
        }

        String value = matcher.group(1).trim();
        return value.isEmpty() ? Optional.empty() : Optional.of(value);
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

    /** Parsed values that map directly to the ticket table columns. */
    private record JobPosting(String title, String description, String location, Integer pay) {
    }
}
