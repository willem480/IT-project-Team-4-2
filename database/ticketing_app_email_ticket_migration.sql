USE ticketing_app;

ALTER TABLE `user`
    ADD UNIQUE KEY uk_user_email (email);

ALTER TABLE ticket
    ADD COLUMN source_email_id VARCHAR(320),
    ADD UNIQUE KEY uk_ticket_source_email_id (source_email_id);
