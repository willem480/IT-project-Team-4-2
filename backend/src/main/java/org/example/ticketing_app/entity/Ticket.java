package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.IdType;
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
public class Ticket implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idTicket", type = IdType.AUTO)
    private Integer idTicket;

    private Integer userId;

    private String title;

    private String description;

    private LocalDateTime datePosted;

    private String location;

    private Integer pay;

    private String email;

    private String sourceEmailId;
}
