package com.arunk.accountmanager;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AuthFlowTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;

    private JsonNode login() throws Exception {
        String body = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"demo@example.com\",\"password\":\"Password123!\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(body);
    }

    @Test
    void rejectsBadPassword() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"demo@example.com\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void accountRequiresToken() throws Exception {
        mvc.perform(get("/api/account/summary")).andExpect(status().isUnauthorized());
    }

    @Test
    void accessTokenUnlocksAccountSummary() throws Exception {
        String access = login().get("accessToken").asText();
        mvc.perform(get("/api/account/summary").header("Authorization", "Bearer " + access))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("demo@example.com"));
    }

    @Test
    void refreshTokenRotatesAndCannotBeReused() throws Exception {
        String refresh = login().get("refreshToken").asText();
        String req = "{\"refreshToken\":\"" + refresh + "\"}";

        String body = mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON).content(req))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        assertThat(json.readTree(body).get("refreshToken").asText()).isNotEqualTo(refresh);

        // Old refresh token was consumed by rotation.
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON).content(req))
                .andExpect(status().isUnauthorized());
    }
}
