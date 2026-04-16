import type { User } from "firebase/auth";
import { getDownloadURL, ref as storageRef } from "firebase/storage";

import { getFirebaseStorage } from "../firebase/client";
import { BACKEND_BASE_URL } from "./constants";
import { createMissingScanAuthError, ScanFlowError, toScanFlowError } from "./errors";
import type { FaceScanResponse } from "./types";

interface StartFaceScanArgs {
  user: User | null;
  frontSource: string;
  sideSource: string;
  email: string | null;
  subscription: string;
  signal?: AbortSignal;
}

function buildFaceScanEndpoint() {
  return `${BACKEND_BASE_URL.replace(/\/+$/, "")}/api/face_scan`;
}

function isUrl(value: string) {
  return /^https?:\/\//i.test(value);
}

function extractBackendMessage(payload: unknown, fallbackText: string) {
  if (payload && typeof payload === "object") {
    const object = payload as Record<string, unknown>;
    const candidates = [
      object.message,
      object.error,
      object.detail,
      Array.isArray(object.errors) &&
      object.errors.length > 0 &&
      typeof object.errors[0] === "object"
        ? (object.errors[0] as Record<string, unknown>).message
        : undefined,
    ];

    const message = candidates.find(
      (candidate) => typeof candidate === "string" && candidate.trim().length > 0,
    );

    if (typeof message === "string") {
      return message;
    }
  }

  return fallbackText;
}

export async function resolveImageSourceToUrl(source: string) {
  if (isUrl(source)) {
    return source;
  }

  return getDownloadURL(storageRef(getFirebaseStorage(), source));
}

export async function startFaceScan<TPayload extends Record<string, unknown>>({
  user,
  frontSource,
  sideSource,
  email,
  subscription,
  signal,
}: StartFaceScanArgs): Promise<FaceScanResponse<TPayload>> {
  if (!user) {
    throw createMissingScanAuthError();
  }

  if (signal?.aborted) {
    throw signal.reason ?? new DOMException("Scan cancelled.", "AbortError");
  }

  const [frontUrl, sideUrl, idToken] = await Promise.all([
    resolveImageSourceToUrl(frontSource),
    resolveImageSourceToUrl(sideSource),
    user.getIdToken(),
  ]);

  const requestBody = {
    FrontimageUrl: frontUrl,
    SideimageUrl: sideUrl,
    email: email ?? null,
    subscription: subscription.trim().toLowerCase(),
  };

  const response = await fetch(buildFaceScanEndpoint(), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify(requestBody),
    signal,
  });

  const rawText = await response.text();
  let payload: unknown = null;

  if (rawText) {
    try {
      payload = JSON.parse(rawText);
    } catch {
      payload = null;
    }
  }

  if (!response.ok) {
    if (response.status === 401) {
      throw new ScanFlowError("unauthorized", "Auth failed: sign in again.", {
        status: 401,
      });
    }

    if (response.status === 403) {
      throw new ScanFlowError(
        "forbidden",
        "Forbidden: email mismatch with authenticated user.",
        { status: 403 },
      );
    }

    throw toScanFlowError({
      message: extractBackendMessage(
        payload,
        rawText || "Something went wrong while scanning. Please try again.",
      ),
      status: response.status,
    });
  }

  console.log("[AIScend] /api/face_scan response", payload);
  console.log(
    "[AIScend] /api/face_scan data",
    payload && typeof payload === "object" ? (payload as Record<string, unknown>).data : null,
  );

  if (
    !payload ||
    typeof payload !== "object" ||
    (payload as Record<string, unknown>).status !== "success" ||
    typeof (payload as Record<string, unknown>).data !== "object"
  ) {
    throw new ScanFlowError(
      "scan-failed",
      "Something went wrong while scanning. Please try again.",
    );
  }

  return payload as FaceScanResponse<TPayload>;
}
