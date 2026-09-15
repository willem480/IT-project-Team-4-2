CREATE DATABASE IF NOT EXISTS ticketing_app
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE ticketing_app;

CREATE TABLE IF NOT EXISTS organization (
    idOrganization INT NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (idOrganization)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `user` (
    idUser INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(200),
    PRIMARY KEY (idUser),
    UNIQUE KEY uk_user_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS team (
    idTeam INT NOT NULL AUTO_INCREMENT,
    organization_id INT,
    PRIMARY KEY (idTeam),
    CONSTRAINT fk_team_organization FOREIGN KEY (organization_id) REFERENCES organization (idOrganization)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS manager (
    idManager INT NOT NULL AUTO_INCREMENT,
    user_id INT,
    organization_id INT,
    PRIMARY KEY (idManager),
    CONSTRAINT fk_manager_user FOREIGN KEY (user_id) REFERENCES `user` (idUser),
    CONSTRAINT fk_manager_organization FOREIGN KEY (organization_id) REFERENCES organization (idOrganization)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS team_member (
    idTeamMember INT NOT NULL AUTO_INCREMENT,
    team_id INT,
    user_id INT,
    organization_id INT,
    PRIMARY KEY (idTeamMember),
    CONSTRAINT fk_team_member_team FOREIGN KEY (team_id) REFERENCES team (idTeam),
    CONSTRAINT fk_team_member_user FOREIGN KEY (user_id) REFERENCES `user` (idUser),
    CONSTRAINT fk_team_member_organization FOREIGN KEY (organization_id) REFERENCES organization (idOrganization)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket (
    idTicket INT NOT NULL AUTO_INCREMENT,
    user_id INT,
    title VARCHAR(998),
    description TEXT,
    date_posted DATETIME,
    location VARCHAR(300),
    pay INT,
    email VARCHAR(200),
    source_email_id VARCHAR(320),
    PRIMARY KEY (idTicket),
    UNIQUE KEY uk_ticket_source_email_id (source_email_id),
    CONSTRAINT fk_ticket_user FOREIGN KEY (user_id) REFERENCES `user` (idUser)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket_assignment (
    idTicketAssignment INT NOT NULL AUTO_INCREMENT,
    user_id INT,
    ticket_id INT,
    date_assigned DATETIME,
    PRIMARY KEY (idTicketAssignment),
    CONSTRAINT fk_ticket_assignment_user FOREIGN KEY (user_id) REFERENCES `user` (idUser),
    CONSTRAINT fk_ticket_assignment_ticket FOREIGN KEY (ticket_id) REFERENCES ticket (idTicket)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket_attachment (
    idTicketAttachment INT NOT NULL AUTO_INCREMENT,
    ticket_id INT,
    attachment_name VARCHAR(45),
    attachment_content LONGBLOB,
    PRIMARY KEY (idTicketAttachment),
    CONSTRAINT fk_ticket_attachment_ticket FOREIGN KEY (ticket_id) REFERENCES ticket (idTicket)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inbox (
    idEmail VARCHAR(320) NOT NULL,
    date_sent DATETIME,
    sender VARCHAR(320),
    receiver VARCHAR(320),
    subject VARCHAR(998),
    body TEXT,
    status VARCHAR(20),
    date_received DATETIME,
    PRIMARY KEY (idEmail)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS outbox LIKE inbox;

CREATE TABLE IF NOT EXISTS organization_report (
    idOrganizationReport INT NOT NULL AUTO_INCREMENT,
    organization_id INT,
    PRIMARY KEY (idOrganizationReport),
    CONSTRAINT fk_organization_report_organization FOREIGN KEY (organization_id) REFERENCES organization (idOrganization)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS team_report (
    idTeamReport INT NOT NULL AUTO_INCREMENT,
    team_id INT,
    PRIMARY KEY (idTeamReport),
    CONSTRAINT fk_team_report_team FOREIGN KEY (team_id) REFERENCES team (idTeam)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS member_report (
    idMemberReport INT NOT NULL AUTO_INCREMENT,
    teammember_id INT,
    PRIMARY KEY (idMemberReport),
    CONSTRAINT fk_member_report_team_member FOREIGN KEY (teammember_id) REFERENCES team_member (idTeamMember)
) ENGINE=InnoDB;
