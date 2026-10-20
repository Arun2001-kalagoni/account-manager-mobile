import { StyleSheet, Text, TextInput, TextInputProps, View } from 'react-native';
import { colors, font, radius, spacing } from '../theme/theme';

type Props = TextInputProps & { label: string; error?: string };

export default function TextField({ label, error, style, ...inputProps }: Props) {
  return (
    <View style={styles.wrapper}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={colors.muted}
        style={[styles.input, error ? styles.inputError : null, style]}
        {...inputProps}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: { gap: spacing.xs },
  label: { fontSize: font.caption, color: colors.text, fontWeight: '600' },
  input: {
    minHeight: 48,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.sm,
    paddingHorizontal: spacing.md,
    fontSize: font.body,
    color: colors.text,
    backgroundColor: colors.surface,
  },
  inputError: { borderColor: colors.danger },
  error: { fontSize: font.caption, color: colors.danger },
});
