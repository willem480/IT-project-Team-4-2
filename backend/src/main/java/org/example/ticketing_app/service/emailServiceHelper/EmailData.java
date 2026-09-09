package org.example.ticketing_app.service.emailServiceHelper;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class EmailData {
    String messageId;
    String from;
    String to;
    String subject;
    String body;
}

