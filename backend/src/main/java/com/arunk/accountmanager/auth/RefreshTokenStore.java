package com.arunk.accountmanager.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Opaque refresh tokens with rotation: every refresh consumes the old token and issues a new one,
 * so a stolen refresh token can only be used once. In-memory for the demo; swap for a database in production.
 */
@Component
public class RefreshTokenStore {

    private record Entry(String username, Instant expiresAt) {}

    private final Map<String, Entry> tokens = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();
    private final Duration ttl;

    public RefreshTokenStore(@Value("${app.jwt.refresh-token-days}") long refreshTokenDays) {
        this.ttl = Duration.ofDays(refreshTokenDays);
    }

    public String issue(String username) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        tokens.put(token, new Entry(username, Instant.now().plus(ttl)));
        return token;
    }

    /** Consumes the token (one-time use) and returns its owner if it was still valid. */
    public Optional<String> consume(String token) {
        Entry entry = tokens.remove(token);
        if (entry == null || entry.expiresAt().isBefore(Instant.now())) {
            return Optional.empty();
        }
        return Optional.of(entry.username());
    }

    public void revoke(String token) {
        tokens.remove(token);
    }
}
