package com.nhtl.security;

import org.apache.commons.codec.binary.Base32;
import java.security.SecureRandom;

public class OtpUtil {
    
    private static final int OTP_LENGTH = 6;
    private static final int OTP_VALIDITY_MINUTES = 10; // 10 minutes
    
    /**
     * Générer un OTP aléatoire 6 chiffres
     */
    public static String generateOtp() {
        SecureRandom random = new SecureRandom();
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }
    
    /**
     * Vérifier si l'OTP a expiré (stocké avec timestamp)
     */
    public static boolean isOtpExpired(long otpTimestamp) {
        long currentTime = System.currentTimeMillis();
        long otpAge = currentTime - otpTimestamp;
        long expirationTime = OTP_VALIDITY_MINUTES * 60 * 1000;
        return otpAge > expirationTime;
    }
    
    /**
     * Générer une clé secrète pour 2FA (optionnel pour futur)
     */
    public static String generateSecretKey() {
        SecureRandom random = new SecureRandom();
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        Base32 base32 = new Base32();
        return base32.encodeToString(bytes);
    }
}