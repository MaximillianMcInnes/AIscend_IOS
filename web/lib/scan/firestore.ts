import type { User } from "firebase/auth";
import {
  addDoc,
  collection,
  doc,
  runTransaction,
  serverTimestamp,
} from "firebase/firestore";

import { getFirebaseFirestore } from "../firebase/client";
import { createMissingScanAuthError } from "./errors";
import type { SaveScanToFirestoreArgs } from "./types";

export async function saveScanToFirestore({
  uid,
  email,
  Scantype,
  overallScore,
  jsonData,
  frontImageUrl,
  sideImageUrl,
}: SaveScanToFirestoreArgs) {
  const reference = await addDoc(collection(getFirebaseFirestore(), "Scans"), {
    ownerUid: uid,
    email: email ?? null,
    Scantype,
    type: Scantype,
    overallScore,
    jsonData,
    payloadJSON: JSON.stringify(jsonData),
    frontImageUrl,
    sideImageUrl,
    source: "scan-flow",
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  return {
    scanId: reference.id,
  };
}

export async function decrementUserScanBalance({
  user,
  currentScansLeft,
}: {
  user: User | null;
  currentScansLeft: number | null | undefined;
}) {
  if (!user) {
    throw createMissingScanAuthError();
  }

  const firestore = getFirebaseFirestore();
  const userRef = doc(firestore, "Users", user.uid);

  await runTransaction(firestore, async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const existing = snapshot.data() as Record<string, unknown> | undefined;
    const persistedScansLeft =
      typeof existing?.scansLeft === "number" ? existing.scansLeft : currentScansLeft ?? 0;
    const nextScansLeft = Math.max(persistedScansLeft - 1, 0);

    transaction.set(
      userRef,
      {
        scansLeft: nextScansLeft,
        Scanned: true,
        Scaned: true,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  });
}
