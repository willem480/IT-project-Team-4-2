package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

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
public class Team implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTeam")
    private Integer idTeam;

    private Integer organizationIdorganization;
}
