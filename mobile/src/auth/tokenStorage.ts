import * as SecureStore from 'expo-secure-store';

// Tokens live in the platform keystore (iOS Keychain / Android Keystore), never in plain AsyncStorage.
const ACCESS_KEY = 'auth.accessToken';
const REFRESH_KEY = 'auth.refreshToken';

export type Tokens = { accessToken: string; refreshToken: string };

export async function saveTokens(tokens: Tokens): Promise<void> {
  await SecureStore.setItemAsync(ACCESS_KEY, tokens.accessToken);
  await SecureStore.setItemAsync(REFRESH_KEY, tokens.refreshToken);
}

export async function loadTokens(): Promise<Tokens | null> {
  const accessToken = await SecureStore.getItemAsync(ACCESS_KEY);
  const refreshToken = await SecureStore.getItemAsync(REFRESH_KEY);
  return accessToken && refreshToken ? { accessToken, refreshToken } : null;
}

export async function clearTokens(): Promise<void> {
  await SecureStore.deleteItemAsync(ACCESS_KEY);
  await SecureStore.deleteItemAsync(REFRESH_KEY);
}
