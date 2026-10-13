package org.example.ticketing_app.profileHelper;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserReturn {
    @NotNull
    private Integer idUser;

    private String name;
    @Schema(nullable = true)
    private String description;
    private String email;
    private float totalEarnings;
    private float totalEarningsThisMonth;
    private int numberOfEarningsThisMonth;
    private float percentageEarningsCompareToLastMonth;

    @Override
    public String toString() {
        return "UserReturn{" +
                "idUser=" + idUser +
                ", name='" + name + '\'' +
                ", description='" + description + '\'' +
                ", email='" + email + '\'' +
                ", totalEarnings=" + totalEarnings +
                ", totalEarningsThisMonth=" + totalEarningsThisMonth +
                ", numberOfEarningsThisMonth=" + numberOfEarningsThisMonth +
                ", percentageEarningsCompareToLastMonth=" + percentageEarningsCompareToLastMonth +
                '}';
    }
}
