/** Mirrors notification_preferences columns from migration 0012. */
export interface NotificationPreferencesRow {
  notify_sale?: boolean | null;
  notify_stock_in?: boolean | null;
  notify_stock_adjustment?: boolean | null;
  notify_low_stock?: boolean | null;
}

const KNOWN_NOTIFICATION_TYPES = new Set([
  "sale",
  "stock_in",
  "stock_adjustment",
  "low_stock",
  "system",
]);

/** Matches SQL coalesce(np.notify_*, true) — only explicit false disables push. */
export function isPushEnabledForType(
  type: string,
  prefs: NotificationPreferencesRow | null,
): boolean {
  if (!KNOWN_NOTIFICATION_TYPES.has(type)) {
    return false;
  }
  if (type === "system") {
    return true;
  }

  const enabled = (value: boolean | null | undefined): boolean => value !== false;

  switch (type) {
    case "sale":
      return enabled(prefs?.notify_sale);
    case "stock_in":
      return enabled(prefs?.notify_stock_in);
    case "stock_adjustment":
      return enabled(prefs?.notify_stock_adjustment);
    case "low_stock":
      return enabled(prefs?.notify_low_stock);
    default:
      return false;
  }
}
