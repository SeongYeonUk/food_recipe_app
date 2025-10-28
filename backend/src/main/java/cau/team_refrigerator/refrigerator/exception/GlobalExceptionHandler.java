package cau.team_refrigerator.refrigerator.exception;

import cau.team_refrigerator.refrigerator.domain.dto.ApiResponseDto;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponseDto> handleValidation(MethodArgumentNotValidException ex) {
        String message = "요청 값 검증에 실패했습니다.";
        if (!ex.getBindingResult().getFieldErrors().isEmpty()) {
            FieldError fe = ex.getBindingResult().getFieldErrors().get(0);
            if (fe != null && fe.getDefaultMessage() != null) {
                message = fe.getDefaultMessage();
            }
        }
        return new ResponseEntity<>(new ApiResponseDto(HttpStatus.BAD_REQUEST.value(), message), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponseDto> handleIllegalArgument(IllegalArgumentException ex) {
        return new ResponseEntity<>(new ApiResponseDto(HttpStatus.CONFLICT.value(), ex.getMessage()), HttpStatus.CONFLICT);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponseDto> handleDataIntegrity(DataIntegrityViolationException ex) {
        return new ResponseEntity<>(new ApiResponseDto(HttpStatus.CONFLICT.value(), "이미 사용중인 아이디/닉네임입니다."), HttpStatus.CONFLICT);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponseDto> handleGeneric(Exception ex) {
        return new ResponseEntity<>(new ApiResponseDto(HttpStatus.INTERNAL_SERVER_ERROR.value(), ex.getMessage()), HttpStatus.INTERNAL_SERVER_ERROR);
    }
}

