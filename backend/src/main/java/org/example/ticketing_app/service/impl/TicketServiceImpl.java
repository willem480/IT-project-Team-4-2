package org.example.ticketing_app.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.apache.commons.text.similarity.JaroWinklerSimilarity;
import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.service.emailServiceHelper.EmailData;
import org.example.ticketing_app.service.ticketServiceHelper.CreateTicketRequest;
import org.example.ticketing_app.service.ticketServiceHelper.Filter;
import org.example.ticketing_app.service.ticketServiceHelper.TicketStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;
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
@RequiredArgsConstructor
public class TicketServiceImpl extends ServiceImpl<TicketMapper, Ticket> {

    /** Only emails with this phrase in the subject are treated as job postings. */
    private static final String POST_JOB_SUBJECT_MARKER = "post job";

    private static final String STATUS_SUBJECT_MARKER = "status";

    private static final String UPDATE_TICKET_SUBJECT_MARKER = "update ticket";

    private static final String CANCEL_TICKET_SUBJECT_MARKER = "cancel ticket";

    private static final String DELETE_TICKET_SUBJECT_MARKER = "delete ticket";

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
    private static final Pattern TICKET_ID_PATTERN = Pattern.compile(
            "(?im)^\\s*Ticket\\s*ID\\s*:\\s*(.*?)\\s*$"
    );
    private static final Pattern UPDATE_TITLE_PATTERN = Pattern.compile(
            "(?im)^\\s*Title\\s*:\\s*(.*?)\\s*$"
    );
    private static final Pattern UPDATE_DESCRIPTION_PATTERN = Pattern.compile(
            "(?ims)^\\s*Description\\s*:\\s*(.*?)(?=^\\s*(?:Ticket\\s*ID|Title|Location|Pay)\\s*:|\\z)"
    );
    private static final Pattern UPDATE_LOCATION_PATTERN = Pattern.compile(
            "(?im)^\\s*Location\\s*:\\s*(.*?)\\s*$"
    );
    private static final Pattern UPDATE_PAY_PATTERN = Pattern.compile(
            "(?im)^\\s*Pay\\s*:\\s*(.*?)\\s*$"
    );

    private final UserServiceImpl userService;

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

    public boolean isValidPostJobEmail(EmailData emailData) {
        if (!isPostJobEmail(emailData)) {
            return false;
        }

        return parseJobPosting(emailData.getBody()).isPresent();
    }

    public boolean isStatusRequest(EmailData emailData) {
        return emailData != null
                && emailData.getSubject() != null
                && emailData.getSubject().trim().equalsIgnoreCase(STATUS_SUBJECT_MARKER);
    }

    /** Identifies emails that request a change to an existing ticket. */
    public boolean isUpdateTicketEmail(EmailData emailData) {
        return emailData != null
                && emailData.getSubject() != null
                && emailData.getSubject().toLowerCase(Locale.ROOT).contains(UPDATE_TICKET_SUBJECT_MARKER);
    }

    /** Identifies emails that request cancellation of an existing ticket. */
    public boolean isCancelTicketEmail(EmailData emailData) {
        if (emailData == null || emailData.getSubject() == null) {
            return false;
        }

        String subject = emailData.getSubject().toLowerCase(Locale.ROOT);
        return subject.contains(CANCEL_TICKET_SUBJECT_MARKER)
                || subject.contains(DELETE_TICKET_SUBJECT_MARKER);
    }

    /**
     * Updates only the fields supplied by a valid Update Ticket email.
     * The sender must own the ticket and the ticket must still be open.
     */
    @Transactional
    public Ticket updateTicketFromEmail(EmailData emailData) {
        if (!isUpdateTicketEmail(emailData) || emailData.getFrom() == null || emailData.getFrom().isBlank()) {
            return null;
        }

        Optional<TicketUpdate> updateRequest = parseTicketUpdate(emailData.getBody());
        if (updateRequest.isEmpty()) {
            return null;
        }

        Ticket ticket = getById(updateRequest.get().ticketId());
        if (ticket == null
                || ticket.getEmail() == null
                || !ticket.getEmail().trim().equalsIgnoreCase(emailData.getFrom().trim())
                || !TicketStatus.OPEN.name().equals(ticket.getStatus())) {
            return null;
        }

        TicketUpdate update = updateRequest.get();
        if (update.title() != null) {
            ticket.setTitle(update.title());
        }
        if (update.description() != null) {
            ticket.setDescription(update.description());
        }
        if (update.location() != null) {
            ticket.setLocation(update.location());
        }
        if (update.pay() != null) {
            ticket.setPay(update.pay());
        }

        updateById(ticket);
        return ticket;
    }

    /**
     * Cancels an open ticket without deleting its assignments, comments, or attachments.
     * Only the email address that created the ticket may request the cancellation.
     */
    @Transactional
    public Ticket cancelTicketFromEmail(EmailData emailData) {
        if (!isCancelTicketEmail(emailData) || emailData.getFrom() == null || emailData.getFrom().isBlank()) {
            return null;
        }

        Optional<Integer> ticketId = parseTicketId(emailData.getBody());
        if (ticketId.isEmpty()) {
            return null;
        }

        Ticket ticket = getById(ticketId.get());
        if (ticket == null
                || ticket.getEmail() == null
                || !ticket.getEmail().trim().equalsIgnoreCase(emailData.getFrom().trim())
                || !TicketStatus.OPEN.name().equals(ticket.getStatus())) {
            return null;
        }

        ticket.setStatus(TicketStatus.CANCELLED.name());
        updateById(ticket);
        return ticket;
    }

    public List<Ticket> getTicketsByEmail(String email) {
        if (email == null || email.isBlank()) {
            return Collections.emptyList();
        }

        return lambdaQuery()
                .eq(Ticket::getEmail, email)
                .orderByDesc(Ticket::getDatePosted)
                .list();
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

    /** Parses a partial update while rejecting blank fields and invalid ticket identifiers or pay. */
    private Optional<TicketUpdate> parseTicketUpdate(String body) {
        if (body == null || body.isBlank()) {
            return Optional.empty();
        }

        Optional<Integer> ticketId = parseTicketId(body);
        if (ticketId.isEmpty()) {
            return Optional.empty();
        }

        ParsedField title = optionalField(UPDATE_TITLE_PATTERN, body);
        ParsedField description = optionalField(UPDATE_DESCRIPTION_PATTERN, body);
        ParsedField location = optionalField(UPDATE_LOCATION_PATTERN, body);
        ParsedField payText = optionalField(UPDATE_PAY_PATTERN, body);

        if ((title.present() && title.value().isEmpty())
                || (description.present() && description.value().isEmpty())
                || (location.present() && location.value().isEmpty())
                || (payText.present() && payText.value().isEmpty())) {
            return Optional.empty();
        }
        if (!title.present() && !description.present() && !location.present() && !payText.present()) {
            return Optional.empty();
        }

        Integer pay = null;
        if (payText.present()) {
            String normalizedPay = payText.value().replaceFirst("^\\$\\s*", "");
            try {
                pay = Integer.parseInt(normalizedPay);
            } catch (NumberFormatException exception) {
                return Optional.empty();
            }
        }

        return Optional.of(new TicketUpdate(
                ticketId.get(),
                title.present() ? title.value() : null,
                description.present() ? description.value() : null,
                location.present() ? location.value() : null,
                pay
        ));
    }

    /** Reads a positive Ticket ID from an update or cancellation email. */
    private Optional<Integer> parseTicketId(String body) {
        if (body == null || body.isBlank()) {
            return Optional.empty();
        }

        ParsedField ticketIdField = optionalField(TICKET_ID_PATTERN, body);
        if (!ticketIdField.present() || ticketIdField.value().isEmpty()) {
            return Optional.empty();
        }

        try {
            int ticketId = Integer.parseInt(ticketIdField.value());
            return ticketId > 0 ? Optional.of(ticketId) : Optional.empty();
        } catch (NumberFormatException exception) {
            return Optional.empty();
        }
    }

    private ParsedField optionalField(Pattern pattern, String body) {
        Matcher matcher = pattern.matcher(body);
        if (!matcher.find()) {
            return new ParsedField(false, "");
        }
        return new ParsedField(true, matcher.group(1).trim());
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

    /** Parsed partial update values. Null fields are intentionally left unchanged. */
    private record TicketUpdate(Integer ticketId, String title, String description, String location, Integer pay) {
    }

    private record ParsedField(boolean present, String value) {
    }

    public List<Ticket> getOpenTickets(){
        return lambdaQuery()
                .eq(Ticket::getStatus, TicketStatus.OPEN.name()).list();
    }

    public List<Ticket> getOpenTickets(Filter filter) {
        List<Ticket> tickets = lambdaQuery()
                .eq(Ticket::getStatus, TicketStatus.OPEN.name())
                .list();

        if (filter == null) {
            return tickets;
        }

        switch (filter) {
            case timeAscending -> {
                return tickets.stream()
                        .sorted(Comparator.comparing(Ticket::getDatePosted))
                        .toList();
            }

            case timeDescending -> {
                return tickets.stream()
                        .sorted(Comparator.comparing(Ticket::getDatePosted).reversed())
                        .toList();
            }

            case payAscending -> {
                return tickets.stream()
                        .sorted(Comparator.comparing(Ticket::getPay))
                        .toList();
            }

            case payDescending -> {
                return tickets.stream()
                        .sorted(Comparator.comparing(Ticket::getPay).reversed())
                        .toList();
            }

            default -> {
                return tickets;
            }
        }
    }

    public List<Ticket> getOpenTicketsKeyword(String keyword) {

        List<Ticket> tickets = lambdaQuery()
                .eq(Ticket::getStatus, TicketStatus.OPEN.name())
                .list();

        JaroWinklerSimilarity similarity = new JaroWinklerSimilarity();

        String search = keyword.toLowerCase();

        return tickets.stream()
                .sorted(
                        Comparator
                                .comparingInt((Ticket t) -> {
                                    String title = t.getTitle().toLowerCase();
                                    String description = t.getDescription().toLowerCase();

                                    if (title.equals(search)) {
                                        return 0;
                                    }

                                    if (title.contains(search)) {
                                        return 1;
                                    }

                                    if (description.contains(search)) {
                                        return 2;
                                    }

                                    return 3;
                                })
                                .thenComparingDouble(t -> {
                                    double titleScore = similarity.apply(
                                            search,
                                            t.getTitle().toLowerCase());

                                    double descriptionScore = similarity.apply(
                                            search,
                                            t.getDescription().toLowerCase());

                                    return -Math.max(titleScore, descriptionScore);
                                }))
                .toList();
    }

    @Transactional
    public void completeTicket(int ticketId) {
        Ticket ticket = baseMapper.selectById(ticketId);
        ticket.setStatus(TicketStatus.CLOSED.name());
        ticket.setDateCompleted(LocalDateTime.now());
        saveOrUpdate(ticket);
    }

    public List<Ticket> getPostedTickets(int posterId, Filter filter) {
        List<Ticket> tickets = lambdaQuery().eq(Ticket::getPosterId, posterId).eq(Ticket::getStatus, TicketStatus.OPEN).list();
        if (filter != null){
            switch (filter) {
                case timeAscending -> {
                    return tickets.stream()
                            .sorted(Comparator.comparing(Ticket::getDatePosted))
                            .toList();
                }

                case timeDescending -> {
                    return tickets.stream()
                            .sorted(Comparator.comparing(Ticket::getDatePosted).reversed())
                            .toList();
                }

                case payAscending -> {
                    return tickets.stream()
                            .sorted(Comparator.comparing(Ticket::getPay))
                            .toList();
                }

                case payDescending -> {
                    return tickets.stream()
                            .sorted(Comparator.comparing(Ticket::getPay).reversed())
                            .toList();
                }

                default -> {
                    return tickets;
                }
            }
        }
        else return tickets;
    }
}
