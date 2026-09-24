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
public class Organization implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "idOrganization", type = IdType.AUTO)
    private Integer idOrganization;

    private String name;
}
