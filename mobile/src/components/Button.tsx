import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';
import { colors, font, radius, spacing } from '../theme/theme';

type Props = {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary';
  loading?: boolean;
  disabled?: boolean;
};

export default function Button({ title, onPress, variant = 'primary', loading, disabled }: Props) {
  const isPrimary = variant === 'primary';
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: disabled || loading }}
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.base,
        isPrimary ? styles.primary : styles.secondary,
        (pressed || disabled) && styles.dimmed,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={isPrimary ? colors.surface : colors.primary} />
      ) : (
        <Text style={[styles.label, { color: isPrimary ? colors.surface : colors.primary }]}>{title}</Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: { minHeight: 48, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center', paddingHorizontal: spacing.md },
  primary: { backgroundColor: colors.primary },
  secondary: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.primary },
  dimmed: { opacity: 0.6 },
  label: { fontSize: font.body, fontWeight: '600' },
});
