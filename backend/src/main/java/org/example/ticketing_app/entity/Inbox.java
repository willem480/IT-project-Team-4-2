package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * <p>
 * 
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Getter
@Setter
@ToString
public class Inbox implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idEmail")
    private String idEmail;

    private LocalDateTime dateSent;

    private String sender;

    private String receiver;

    private String subject;

    private String body;

    private String status;

    private LocalDateTime dateReceived;
}
