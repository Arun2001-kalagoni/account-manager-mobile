import { ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors, font, radius, spacing } from '../theme/theme';

export default function Card({ title, children }: { title?: string; children: ReactNode }) {
  return (
    <View style={styles.card}>
      {title ? <Text style={styles.title}>{title}</Text> : null}
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.md,
    gap: spacing.sm,
  },
  title: { fontSize: font.caption, fontWeight: '700', color: colors.muted, textTransform: 'uppercase' },
});
