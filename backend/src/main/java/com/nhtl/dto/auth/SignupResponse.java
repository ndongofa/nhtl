package com.nhtl.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SignupResponse {
    
    private String userId;  // ✅ STRING, pas UUID!
    private String email;
    private String phone;
    private String username;
    private String message;
}