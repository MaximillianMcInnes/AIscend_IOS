"use client";

import type { User } from "firebase/auth";
import { doc, getDoc, onSnapshot } from "firebase/firestore";
import { useCallback, useEffect, useState } from "react";

import { getFirebaseFirestore, isFirebaseConfigured } from "../lib/firebase/client";

export interface UserProfile {
  uid: string;
  email: string | null;
  subscription: string;
  scansLeft: number;
  Scanned: boolean;
  Scaned: boolean;
}

interface UseUserProfileResult {
  profile: UserProfile | null;
  isLoading: boolean;
  error: string | null;
  refreshProfile: () => Promise<UserProfile | null>;
}

function normalizeProfile(user: User, raw: Record<string, unknown> | undefined): UserProfile {
  const subscription =
    (typeof raw?.subscription === "string" && raw.subscription) ||
    (typeof raw?.Subscription === "string" && raw.Subscription) ||
    "free";

  const rawScansLeft =
    (typeof raw?.scansLeft === "number" && raw.scansLeft) ||
    (typeof raw?.ScansLeft === "number" && raw.ScansLeft) ||
    0;

  return {
    uid: user.uid,
    email:
      (typeof raw?.email === "string" && raw.email) ||
      (typeof raw?.Email === "string" && raw.Email) ||
      user.email ||
      null,
    subscription,
    scansLeft: Number.isFinite(rawScansLeft) ? rawScansLeft : 0,
    Scanned: Boolean(raw?.Scanned),
    Scaned: Boolean(raw?.Scaned),
  };
}

export function useUserProfile(user: User | null): UseUserProfileResult {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState(Boolean(user));
  const [error, setError] = useState<string | null>(null);

  const refreshProfile = useCallback(async () => {
    if (!user || !isFirebaseConfigured()) {
      return null;
    }

    const snapshot = await getDoc(doc(getFirebaseFirestore(), "Users", user.uid));
    const normalized = normalizeProfile(
      user,
      (snapshot.data() as Record<string, unknown> | undefined) ?? undefined,
    );
    setProfile(normalized);
    return normalized;
  }, [user]);

  useEffect(() => {
    if (!user) {
      setProfile(null);
      setError(null);
      setIsLoading(false);
      return undefined;
    }

    if (!isFirebaseConfigured()) {
      setError("Firebase web config is missing, so the user profile cannot load.");
      setIsLoading(false);
      return undefined;
    }

    setIsLoading(true);
    const reference = doc(getFirebaseFirestore(), "Users", user.uid);

    const unsubscribe = onSnapshot(
      reference,
      (snapshot) => {
        const normalized = normalizeProfile(
          user,
          (snapshot.data() as Record<string, unknown> | undefined) ?? undefined,
        );
        setProfile(normalized);
        setError(null);
        setIsLoading(false);
      },
      (nextError) => {
        setError(nextError.message || "Could not load the current user profile.");
        setIsLoading(false);
      },
    );

    return unsubscribe;
  }, [user]);

  return { profile, isLoading, error, refreshProfile };
}
