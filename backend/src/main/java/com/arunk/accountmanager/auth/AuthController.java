package com.arunk.accountmanager.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    public record LoginRequest(@NotBlank String username, @NotBlank String password) {}
    public record RefreshRequest(@NotBlank String refreshToken) {}
    public record TokenResponse(String accessToken, String refreshToken, long expiresIn) {}

    private final JwtService jwtService;
    private final RefreshTokenStore refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final Map<String, String> users;

    public AuthController(JwtService jwtService, RefreshTokenStore refreshTokens, PasswordEncoder passwordEncoder) {
        this.jwtService = jwtService;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        // Demo user for local testing. Passwords are stored as BCrypt hashes, never in plain text.
        this.users = Map.of("demo@example.com", passwordEncoder.encode("Password123!"));
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        String hash = users.get(request.username());
        if (hash == null || !passwordEncoder.matches(request.password(), hash)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(tokensFor(request.username()));
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return refreshTokens.consume(request.refreshToken())
                .map(username -> ResponseEntity.ok(tokensFor(username)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@Valid @RequestBody RefreshRequest request) {
        refreshTokens.revoke(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    private TokenResponse tokensFor(String username) {
        return new TokenResponse(
                jwtService.issueAccessToken(username),
                refreshTokens.issue(username),
                jwtService.accessTokenTtlSeconds());
    }
}
