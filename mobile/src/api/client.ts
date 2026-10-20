import Constants from 'expo-constants';
import { clearTokens, loadTokens, saveTokens, Tokens } from '../auth/tokenStorage';

const BASE_URL: string =
  (Constants.expoConfig?.extra as { apiBaseUrl?: string } | undefined)?.apiBaseUrl ?? 'http://localhost:8080';

type TokenResponse = { accessToken: string; refreshToken: string; expiresIn: number };

export class UnauthorizedError extends Error {}

// Lets the auth layer react (log out) when a session can no longer be refreshed.
let onSessionExpired: () => void = () => {};
export function setSessionExpiredHandler(handler: () => void) {
  onSessionExpired = handler;
}

// Only one refresh call runs at a time, even if several requests hit a 401 together.
let refreshInFlight: Promise<Tokens | null> | null = null;

async function refreshTokens(): Promise<Tokens | null> {
  if (!refreshInFlight) {
    refreshInFlight = (async () => {
      const current = await loadTokens();
      if (!current) return null;
      const res = await fetch(`${BASE_URL}/api/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: current.refreshToken }),
      });
      if (!res.ok) return null;
      const data: TokenResponse = await res.json();
      const next = { accessToken: data.accessToken, refreshToken: data.refreshToken };
      await saveTokens(next);
      return next;
    })().finally(() => {
      refreshInFlight = null;
    });
  }
  return refreshInFlight;
}

export async function login(username: string, password: string): Promise<void> {
  const res = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  if (res.status === 401) throw new UnauthorizedError('Incorrect email or password.');
  if (!res.ok) throw new Error('Sign-in failed. Please try again.');
  const data: TokenResponse = await res.json();
  await saveTokens({ accessToken: data.accessToken, refreshToken: data.refreshToken });
}

export async function logout(): Promise<void> {
  const tokens = await loadTokens();
  if (tokens) {
    await fetch(`${BASE_URL}/api/auth/logout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: tokens.refreshToken }),
    }).catch(() => undefined);
  }
  await clearTokens();
}

/** Authenticated GET that silently refreshes an expired access token once, then retries. */
export async function authGet<T>(path: string): Promise<T> {
  const tokens = await loadTokens();
  if (!tokens) throw new UnauthorizedError('Not signed in.');

  const call = (accessToken: string) =>
    fetch(`${BASE_URL}${path}`, { headers: { Authorization: `Bearer ${accessToken}` } });

  let res = await call(tokens.accessToken);
  if (res.status === 401) {
    const refreshed = await refreshTokens();
    if (!refreshed) {
      await clearTokens();
      onSessionExpired();
      throw new UnauthorizedError('Session expired. Please sign in again.');
    }
    res = await call(refreshed.accessToken);
  }
  if (!res.ok) throw new Error(`Request failed (${res.status}).`);
  return (await res.json()) as T;
}
