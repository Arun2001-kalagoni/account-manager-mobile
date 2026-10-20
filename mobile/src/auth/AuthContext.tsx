import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import * as api from '../api/client';
import { loadTokens } from './tokenStorage';

type AuthState = {
  status: 'loading' | 'signedOut' | 'signedIn';
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthState['status']>('loading');

  useEffect(() => {
    api.setSessionExpiredHandler(() => setStatus('signedOut'));
    loadTokens().then((tokens) => setStatus(tokens ? 'signedIn' : 'signedOut'));
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    await api.login(email.trim(), password);
    setStatus('signedIn');
  }, []);

  const signOut = useCallback(async () => {
    await api.logout();
    setStatus('signedOut');
  }, []);

  const value = useMemo(() => ({ status, signIn, signOut }), [status, signIn, signOut]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
