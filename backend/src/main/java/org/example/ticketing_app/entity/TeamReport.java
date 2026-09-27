package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
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
 * @since 2026-09-27
 */
@Getter
@Setter
@ToString
@TableName("team_report")
public class TeamReport implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idTeamReport", type = IdType.AUTO)
    private Integer idTeamReport;

    private Integer teamId;

    private String title;

    private String body;

    private LocalDateTime dateGenerated;
}
