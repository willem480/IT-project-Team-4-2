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
public class Teammember implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTeamMember")
    private Integer idTeamMember;

    private Integer teamIdteam;

    private Integer userIduser;

    private Integer organizationIdorganization;
}
