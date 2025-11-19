package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LogController {

    private static final Logger log = LoggerFactory.getLogger(LogController.class);

    @GetMapping("/generate-log")
    public String generateLog(@RequestParam(defaultValue = "INFO") String level,
                              @RequestParam(defaultValue = "Тестовое сообщение") String message) {

        String response = String.format("Сгенерирован лог уровня: %s с сообщением: %s", level, message);

        switch (level.toUpperCase()) {
            case "TRACE":
                log.trace("TRACE-лог: {}", message);
                break;
            case "DEBUG":
                log.debug("DEBUG-лог: {}", message);
                break;
            case "INFO":
                log.info("INFO-лог: {}", message);
                break;
            case "WARN":
                log.warn("WARN-лог: {}", message);
                break;
            case "ERROR":
                log.error("ERROR-лог: {}. Произошла имитация ошибки.", message);
                break;
            default:
                log.info("Неизвестный уровень. Сгенерирован INFO-лог: {}", message);
                response = "Неизвестный уровень. " + response;
        }

        return response;
    }
}