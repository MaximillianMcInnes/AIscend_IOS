import { LAST_SCAN_SESSION_KEY } from "./constants";
import type { PersistedLastScanResult } from "./types";

export function persistLatestScanResult(result: PersistedLastScanResult) {
  if (typeof window === "undefined") {
    return;
  }

  sessionStorage.setItem(LAST_SCAN_SESSION_KEY, JSON.stringify(result));
}

export function readLatestScanResult(): PersistedLastScanResult | null {
  if (typeof window === "undefined") {
    return null;
  }

  const rawValue = sessionStorage.getItem(LAST_SCAN_SESSION_KEY);
  if (!rawValue) {
    return null;
  }

  try {
    return JSON.parse(rawValue) as PersistedLastScanResult;
  } catch {
    return null;
  }
}
