// RefrigeratorController.java
package cau.team_refrigerator.refrigerator.controller;

import cau.team_refrigerator.refrigerator.domain.Refrigerator;
import cau.team_refrigerator.refrigerator.domain.User;
import cau.team_refrigerator.refrigerator.domain.dto.RefrigeratorResponseDto;
import cau.team_refrigerator.refrigerator.repository.RefrigeratorRepository;
import cau.team_refrigerator.refrigerator.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/refrigerators")
@RequiredArgsConstructor
public class RefrigeratorController {

    private final RefrigeratorRepository refrigeratorRepository;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<RefrigeratorResponseDto>> getMyRefrigerators(Principal principal) {
        User currentUser = userService.getUserById(principal.getName());
        List<Refrigerator> refrigerators = refrigeratorRepository.findAllByUser(currentUser);
        List<RefrigeratorResponseDto> dtoList = refrigerators.stream()
                .map(RefrigeratorResponseDto::new)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtoList);
    }
}