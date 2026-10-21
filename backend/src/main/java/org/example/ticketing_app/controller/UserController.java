package org.example.ticketing_app.controller;

import lombok.RequiredArgsConstructor;
import org.example.ticketing_app.service.impl.UserServiceImpl;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import org.example.ticketing_app.profileHelper.UserReturn;
import org.example.ticketing_app.service.userServiceHelper.SignInRequest;
import org.example.ticketing_app.service.userServiceHelper.SignUpRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;

import java.util.List;

/**
 * <p>
 *  前端控制器
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {
    private final UserServiceImpl userService;

    @PostMapping("updateUser")
    public void UpdateUser(@RequestParam int id, @RequestParam(required = false) String name, @RequestParam(required = false) String email, @RequestParam(required = false) String description) {
        userService.UpdateUser(id, email, name, description);
    }

    @PostMapping("/signup")
    @ResponseStatus(HttpStatus.CREATED)
    public UserReturn signUp(@RequestBody SignUpRequest request) {
        return userService.signUp(request);
    }

    @PostMapping("/signin")
    public UserReturn signIn(@RequestBody SignInRequest request) {
        return userService.signIn(request);
    }

    @PostMapping("getUsersByEmail")
    public List<UserReturn> getUsersByKeyWord(@RequestParam(required = false) String keyword) {
        return userService.getUsersByKeyword(keyword);
    }
}
