/** Redact UUIDs/tokens for safe production logs. */
export function redactId(value: string | null | undefined): string {
  if (!value) return "none";
  const trimmed = value.trim();
  if (trimmed.length <= 8) return "***";
  return `${trimmed.slice(0, 4)}…${trimmed.slice(-4)}`;
}

export function tokenSuffix(token: string): string {
  const trimmed = token.trim();
  if (trimmed.length <= 8) return "***";
  return trimmed.slice(-8);
}
