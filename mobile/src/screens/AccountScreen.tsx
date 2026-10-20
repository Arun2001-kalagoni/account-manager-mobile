import { StyleSheet, Text, View } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useAuth } from '../auth/AuthContext';
import Button from '../components/Button';
import Card from '../components/Card';
import Screen from '../components/Screen';
import { RootStackParamList } from '../navigation/RootNavigator';
import { colors, font, spacing } from '../theme/theme';

type Props = NativeStackScreenProps<RootStackParamList, 'Account'>;

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

export default function AccountScreen({ route }: Props) {
  const { summary } = route.params;
  const { signOut } = useAuth();

  return (
    <Screen>
      <Card title="Profile">
        <Row label="Name" value={summary.name} />
        <Row label="Email" value={summary.email} />
      </Card>
      <Card title="Lines">
        {summary.lines.map((line) => (
          <Row key={line.phoneNumber} label={line.name} value={line.plan} />
        ))}
      </Card>
      <Button title="Sign out" variant="secondary" onPress={signOut} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: spacing.xs },
  label: { fontSize: font.body, color: colors.muted },
  value: { fontSize: font.body, color: colors.text, fontWeight: '600' },
});
