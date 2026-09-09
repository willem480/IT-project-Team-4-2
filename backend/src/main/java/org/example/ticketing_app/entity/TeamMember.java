package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
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
@TableName("team_member")
public class TeamMember implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId("idTeamMember")
    private Integer idTeamMember;

    private Integer teamId;

    private Integer userId;

    private Integer organizationId;
}
