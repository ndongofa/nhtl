package com.nhtl.repositories;

import com.nhtl.models.PhoneOtpToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Repository
public interface PhoneOtpTokenRepository extends JpaRepository<PhoneOtpToken, String> {

    /** Supprime tous les tokens dont la date d'expiration est dépassée. */
    @Transactional
    @Modifying
    @Query("DELETE FROM PhoneOtpToken t WHERE t.expiresAt < :now")
    int deleteAllExpiredBefore(Instant now);
}
