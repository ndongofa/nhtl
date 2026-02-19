package com.nhtl.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    
    private String userId;  // ✅ STRING, pas UUID!
    private String email;
    private String phone;
    private String fullName;
    private String role;
    private String accessToken;
    private String refreshToken;
    private long expiresIn;
}