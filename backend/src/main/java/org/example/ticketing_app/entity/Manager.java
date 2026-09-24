package org.example.ticketing_app.entity;

import com.baomidou.mybatisplus.annotation.IdType;
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
 * @since 2026-09-24
 */
@Getter
@Setter
@ToString
public class Manager implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idManager", type = IdType.AUTO)
    private Integer idManager;

    private Integer userId;

    private Integer organizationId;
}
