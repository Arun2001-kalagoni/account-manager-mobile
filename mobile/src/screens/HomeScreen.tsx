import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { AccountSummary, getAccountSummary } from '../api/account';
import Button from '../components/Button';
import Card from '../components/Card';
import Screen from '../components/Screen';
import UsageBar from '../components/UsageBar';
import { RootStackParamList } from '../navigation/RootNavigator';
import { colors, font } from '../theme/theme';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export default function HomeScreen({ navigation }: Props) {
  const [summary, setSummary] = useState<AccountSummary | null>(null);
  const [error, setError] = useState<string | undefined>();
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    setError(undefined);
    try {
      setSummary(await getAccountSummary());
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load your account.');
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  if (!summary && !error) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    );
  }

  return (
    <Screen>
      <RefreshControl refreshing={refreshing} onRefresh={async () => { setRefreshing(true); await load(); setRefreshing(false); }} />
      {error ? (
        <Card>
          <Text style={styles.error}>{error}</Text>
          <Button title="Try again" variant="secondary" onPress={load} />
        </Card>
      ) : summary ? (
        <>
          <Text style={styles.greeting}>Hi, {summary.name.split(' ')[0]}</Text>
          <Card title="Balance due">
            <Text style={styles.amount}>${summary.balanceDue.toFixed(2)}</Text>
            <Text style={styles.muted}>Due {new Date(summary.dueDate).toLocaleDateString()}</Text>
          </Card>
          {summary.lines.map((line) => (
            <Card key={line.phoneNumber} title={line.name}>
              <Text style={styles.body}>
                {line.plan} · {line.phoneNumber}
              </Text>
              <UsageBar used={line.dataUsedGb} limit={line.dataLimitGb} unit="GB" />
            </Card>
          ))}
          <Button title="View account" variant="secondary" onPress={() => navigation.navigate('Account', { summary })} />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.background },
  greeting: { fontSize: font.title, fontWeight: '700', color: colors.text },
  amount: { fontSize: 28, fontWeight: '700', color: colors.text },
  body: { fontSize: font.body, color: colors.text },
  muted: { fontSize: font.caption, color: colors.muted },
  error: { fontSize: font.body, color: colors.danger },
});
