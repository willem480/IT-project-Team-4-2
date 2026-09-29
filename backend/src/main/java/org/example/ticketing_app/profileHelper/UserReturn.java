package org.example.ticketing_app.profileHelper;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserReturn {
    @NotNull
    private Integer idUser;

    private String name;

    private String email;
    private float totalEarnings;
    private float totalEarningsThisMonth;
    private int numberOfEarningsThisMonth;
    private float percentageEarningsCompareToLastMonth;
}
