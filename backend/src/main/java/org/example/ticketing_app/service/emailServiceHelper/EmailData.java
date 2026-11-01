package org.example.ticketing_app.service.emailServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@AllArgsConstructor
@ToString
public class EmailData {
    String messageId;
    String from;
    String to;
    String subject;
    String body;
}

