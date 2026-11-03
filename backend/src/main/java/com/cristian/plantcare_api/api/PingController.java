package com.cristian.plantcare_api.api;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

@RestController 
public class PingController {
    public record PingResponse(String status){}
    
    @GetMapping("/api/ping")
    public PingResponse ping() {
        return new PingResponse("ok");
    }
    
}
