package org.example.ticketing_app.service.impl;

import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.example.ticketing_app.entity.User;
import org.example.ticketing_app.mapper.TicketAssignmentMapper;
import org.example.ticketing_app.mapper.UserMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.example.ticketing_app.profileHelper.UserReturn;
import org.example.ticketing_app.service.ticketServiceHelper.TicketAssignmentReturn;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.example.ticketing_app.service.userServiceHelper.SignInRequest;
import org.example.ticketing_app.service.userServiceHelper.SignUpRequest;

import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl extends ServiceImpl<UserMapper, User> {
    private final TicketAssignmentServiceImpl ticketAssignmentService;
    private final TicketAssignmentMapper ticketAssignmentMapper;

    public UserReturn getUserById(int id) {

        User user = getById(id);

        if (user == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    String.format("User not found with id %d", id));
        }

        List<TicketAssignmentReturn> ticketAssignmentReturns =
                ticketAssignmentService.getCompletedTickets(
                        id,
                        null);

        UserReturn userReturn = new UserReturn();

        userReturn.setName(user.getName());
        userReturn.setEmail(user.getEmail());
        userReturn.setIdUser(user.getIdUser());
        userReturn.setDescription(user.getDescription());

        float totalEarnings = 0;
        float totalEarningsThisMonth = 0;
        float totalEarningsLastMonth = 0;
        int numberOfEarningsThisMonth = 0;

        YearMonth currentMonth =
                YearMonth.now();

        YearMonth lastMonth =
                currentMonth.minusMonths(1);

        for (TicketAssignmentReturn ticket : ticketAssignmentReturns) {

            if (ticket.getPay() == null) {
                continue;
            }

            totalEarnings += ticket.getPay();

            if (ticket.getDateCompleted() == null) {
                continue;
            }

            YearMonth completedMonth =
                    YearMonth.from(
                            ticket.getDateCompleted());

            if (completedMonth.equals(currentMonth)) {

                totalEarningsThisMonth +=
                        ticket.getPay();

                numberOfEarningsThisMonth++;

            } else if (completedMonth.equals(lastMonth)) {

                totalEarningsLastMonth +=
                        ticket.getPay();
            }
        }

        float percentageChange;

        if (totalEarningsLastMonth == 0) {

            percentageChange =
                    totalEarningsThisMonth > 0
                            ? 100
                            : 0;

        } else {

            percentageChange =
                    ((totalEarningsThisMonth
                            - totalEarningsLastMonth)
                            / totalEarningsLastMonth)
                            * 100;
        }

        userReturn.setTotalEarnings(
                totalEarnings);

        userReturn.setTotalEarningsThisMonth(
                totalEarningsThisMonth);

        userReturn.setNumberOfEarningsThisMonth(
                numberOfEarningsThisMonth);

        userReturn.setPercentageEarningsCompareToLastMonth(
                percentageChange);

        return userReturn;
    }

    public void UpdateUser(int userId, String newEmail, String newName, String newDescription) {
        User user = getById(userId);
        if (user != null) {
            if (!StringUtils.isBlank(newEmail)) {
                user.setEmail(newEmail);
            }
            else if (!StringUtils.isBlank(newName)) {
                user.setName(newName);
            }

            else if (!StringUtils.isBlank(newDescription)) {
                user.setDescription(newDescription);
            }
            saveOrUpdate(user);
        }
    }

    private UserReturn createBasicUserReturn(User user) {

        UserReturn userReturn = new UserReturn();

        userReturn.setIdUser(user.getIdUser());
        userReturn.setName(user.getName());
        userReturn.setEmail(user.getEmail());
        userReturn.setDescription(user.getDescription());

        return userReturn;
    }

    public UserReturn signUp(SignUpRequest request) {

        if (request == null
                || StringUtils.isBlank(request.getName())
                || StringUtils.isBlank(request.getEmail())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Name and email are required");
        }

        User existingUser = getOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getEmail, request.getEmail())
        );

        if (existingUser != null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Email is already registered");
        }

        User user = new User();

        user.setName(request.getName());
        user.setEmail(request.getEmail());

        save(user);


        return createBasicUserReturn(user);
    }


    public UserReturn signIn(SignInRequest request) {

        if (request == null
                || StringUtils.isBlank(request.getEmail())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Email is required");
        }

        User user = getOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getEmail, request.getEmail())
        );

        if (user == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "User not found");
        }

        return createBasicUserReturn(user);
    }

    public List<UserReturn> getUsersByEmail(String email) {
        if (StringUtils.isBlank(email)) {
            return list().stream().map(user -> createBasicUserReturn(user)).collect(Collectors.toList());
        }
        List<User> users = list(new LambdaQueryWrapper<User>().eq(User::getEmail, email));
        return users.stream().map(user -> createBasicUserReturn(user)).collect(Collectors.toList());
    }
}
