"use client";

import { User, onAuthStateChanged } from "firebase/auth";
import { useEffect, useState } from "react";

import { getFirebaseAuth, isFirebaseConfigured } from "../lib/firebase/client";

interface AuthSessionState {
  user: User | null;
  isLoading: boolean;
  error: string | null;
}

export function useAuthSession(): AuthSessionState {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isFirebaseConfigured()) {
      setError(
        "Firebase web config is missing. Add NEXT_PUBLIC_FIREBASE_* variables to enable auth and uploads.",
      );
      setIsLoading(false);
      return undefined;
    }

    const auth = getFirebaseAuth();

    const unsubscribe = onAuthStateChanged(
      auth,
      (nextUser) => {
        setUser(nextUser);
        setError(null);
        setIsLoading(false);
      },
      (nextError) => {
        setUser(null);
        setError(nextError.message || "Failed to load the current auth session.");
        setIsLoading(false);
      },
    );

    return unsubscribe;
  }, []);

  return { user, isLoading, error };
}
