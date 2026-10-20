import { StyleSheet, Text, View } from 'react-native';
import { colors, font, radius, spacing } from '../theme/theme';

export default function UsageBar({ used, limit, unit }: { used: number; limit: number; unit: string }) {
  const pct = limit > 0 ? Math.min(used / limit, 1) : 0;
  return (
    <View style={styles.wrapper}>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${pct * 100}%` }]} />
      </View>
      <Text style={styles.caption}>
        {used} of {limit} {unit} used
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { gap: spacing.xs },
  track: { height: 8, borderRadius: radius.sm, backgroundColor: colors.border, overflow: 'hidden' },
  fill: { height: '100%', backgroundColor: colors.primary },
  caption: { fontSize: font.caption, color: colors.muted },
});
