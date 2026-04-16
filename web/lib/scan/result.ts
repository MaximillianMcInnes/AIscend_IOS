export function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

export function getOverallScore(payload: unknown, fallback = 5.0) {
  if (!payload || typeof payload !== "object") {
    return fallback;
  }

  const scores = (payload as Record<string, unknown>).Scores;
  if (!scores || typeof scores !== "object") {
    return fallback;
  }

  const rawValue = (scores as Record<string, unknown>).overall;
  const score = typeof rawValue === "number" ? rawValue : Number(rawValue);
  return Number.isFinite(score) ? score : fallback;
}
