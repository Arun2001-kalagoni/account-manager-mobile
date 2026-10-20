import { useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import { useAuth } from '../auth/AuthContext';
import Button from '../components/Button';
import Card from '../components/Card';
import Screen from '../components/Screen';
import TextField from '../components/TextField';
import { colors, font } from '../theme/theme';

export default function LoginScreen() {
  const { signIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);

  const canSubmit = email.includes('@') && password.length >= 8;

  async function onSubmit() {
    setError(undefined);
    setLoading(true);
    try {
      await signIn(email, password);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Sign-in failed.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Screen>
      <Text style={styles.heading}>Welcome back</Text>
      <Text style={styles.sub}>Sign in to manage your account, plans, and devices.</Text>
      <Card>
        <TextField
          label="Email"
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          autoComplete="email"
          keyboardType="email-address"
          textContentType="username"
        />
        <TextField
          label="Password"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          autoComplete="password"
          textContentType="password"
          error={error}
        />
        <Button title="Sign in" onPress={onSubmit} loading={loading} disabled={!canSubmit} />
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  heading: { fontSize: font.title, fontWeight: '700', color: colors.text },
  sub: { fontSize: font.body, color: colors.muted },
});
