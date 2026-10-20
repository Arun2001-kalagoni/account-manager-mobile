# Account Manager Mobile App

An account management app for Android and iOS, backed by a **Spring Boot** API with **JWT authentication**. It comes in two clients that share the same API:

- **`ios/`**: a native iOS app in **Swift and SwiftUI** (iOS 16+), with Keychain token storage and XCTest coverage.
- **`mobile/`**: a cross-platform app in **React Native, TypeScript, and Expo**.

Customers sign in, land on a personalized home screen with their balance and per-line data usage, and can open an account view with profile and line details.

## Features

- **Secure sign-in**: email/password login against the Spring Boot API.
- **JWT sessions**: short-lived access tokens (15 min) plus rotating one-time refresh tokens (7 days).
- **Secure token storage**: tokens are kept in the iOS Keychain / Android Keystore via `expo-secure-store`, never in plain storage.
- **Automatic session refresh**: the API client retries a request once after a 401 by refreshing the token. Concurrent 401s share a single refresh call. If the refresh fails, the user is signed out.
- **Personalized home screen**: greeting, balance due, and data usage per line, with pull-to-refresh and error and retry states.
- **Reusable component library**: `Button`, `Card`, `TextField`, `Screen`, and `UsageBar`, all driven by shared theme tokens so every screen looks consistent on both platforms.
- **Auth-gated navigation**: signed-out users only see the login stack; signed-in users only see the app stack.

## Native iOS app (Swift, SwiftUI)

- **SwiftUI screens**: login, home (balance and per-line data usage with pull-to-refresh), and account, built with `NavigationStack`.
- **MVVM**: `AuthViewModel` and `HomeViewModel` are `@MainActor` observable objects; views only render state.
- **Keychain sessions**: `KeychainTokenStore` saves tokens with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- **Token refresh in an actor**: `APIClient` is a Swift `actor`. On a 401 it refreshes once and retries. Concurrent requests share one in-flight refresh, and a failed refresh clears the session and returns the user to login.
- **Reusable components**: `PrimaryButton`, `CardView`, `LabeledField`, and `UsageBar`, styled from one `Theme`.
- **Tests**: `APIClientTests` uses a stubbed `URLProtocol` to cover login, wrong password, refresh-and-retry, concurrent refresh, and failed refresh.

```
ios/
  project.yml                  XcodeGen spec (app + unit-test targets)
  AccountManager/
    App/                       AccountManagerApp, RootView (auth-gated navigation)
    Auth/                      AuthViewModel, TokenStore (Keychain)
    Networking/                APIClient (actor), APIError
    Models/                    AccountSummary, Line
    Components/                Theme, PrimaryButton, CardView, LabeledField, UsageBar
    Features/                  Login, Home (view + view model), Account
  AccountManagerTests/         APIClientTests, TestSupport (URLProtocol stub, in-memory store)
```

Run it (macOS with Xcode 15+):

```bash
brew install xcodegen
cd ios
xcodegen generate
open AccountManager.xcodeproj      # Run on an iPhone simulator; Cmd+U runs the tests
```

The API base URL is `API_BASE_URL` in `ios/project.yml` (default `http://localhost:8080`, which the iOS simulator can reach).

## React Native app: project structure

```
backend/                 Spring Boot 3 API (Java 17)
  auth/                  JwtService, RefreshTokenStore, AuthController (/api/auth/login, /refresh, /logout)
  account/               AccountController (/api/account/summary)
  security/              JwtAuthFilter, SecurityConfig (stateless, 401 on missing/invalid token)
  src/test/              AuthFlowTest (login, protected route, refresh rotation and reuse rejection)
mobile/                  Expo React Native app (TypeScript)
  App.tsx
  src/api/               client.ts (auth calls + refresh-on-401), account.ts
  src/auth/              AuthContext.tsx, tokenStorage.ts (SecureStore)
  src/components/        Button, Card, TextField, Screen, UsageBar
  src/navigation/        RootNavigator.tsx
  src/screens/           LoginScreen, HomeScreen, AccountScreen
  src/theme/             theme.ts (colors, spacing, radius, font)
```

## Running locally

### 1. Backend

```bash
cd backend
mvn spring-boot:run          # starts on http://localhost:8080
mvn test                     # runs the auth flow tests
```

Set a real signing key outside of local development:

```bash
export APP_JWT_SECRET="a-long-random-secret-of-at-least-32-bytes"
```

Demo user: `demo@example.com` / `Password123!`

### 2. React Native app

```bash
cd mobile
npm install
npm run typecheck
npx expo start               # press a for Android emulator, i for iOS simulator
```

The API base URL is set in `mobile/app.json` under `expo.extra.apiBaseUrl`.
- iOS simulator: `http://localhost:8080`
- Android emulator: `http://10.0.2.2:8080`
- Physical device: your computer's LAN IP, e.g. `http://192.168.1.20:8080`

## API

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/login` | none | Returns `{ accessToken, refreshToken, expiresIn }` |
| POST | `/api/auth/refresh` | none | Exchanges a refresh token for a new pair; the old refresh token is revoked |
| POST | `/api/auth/logout` | none | Revokes the refresh token |
| GET | `/api/account/summary` | Bearer | Name, email, balance due, due date, and lines with data usage |

## Possible next steps

- Persist users and refresh tokens in a database instead of in memory.
- Add biometric unlock (Face ID / fingerprint) with `expo-local-authentication`.
- Add component tests with React Native Testing Library.
