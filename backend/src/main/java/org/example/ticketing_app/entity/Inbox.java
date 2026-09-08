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
    private Integer idEmail;

    private LocalDateTime date;

    private String from;

    private String to;

    private String subject;

    private String body;

    private String status;
}
