package com.arunk.accountmanager.account;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Account data behind the home and account screens. Sample data for the demo. */
@RestController
@RequestMapping("/api/account")
public class AccountController {

    public record Line(String name, String phoneNumber, String plan, double dataUsedGb, double dataLimitGb) {}
    public record Summary(String name, String email, BigDecimal balanceDue, LocalDate dueDate, List<Line> lines) {}

    @GetMapping("/summary")
    public Summary summary(Authentication auth) {
        return new Summary(
                "Demo User",
                auth.getName(),
                new BigDecimal("85.00"),
                LocalDate.now().plusDays(12),
                List.of(
                        new Line("My Phone", "(555) 010-2030", "Unlimited Plus", 18.4, 50),
                        new Line("Tablet", "(555) 010-4050", "Data Only", 2.1, 10)));
    }
}
