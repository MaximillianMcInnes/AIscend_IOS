export type ScanFlowErrorCode =
  | "invalid-image-type"
  | "too-large"
  | "missing-auth-upload"
  | "missing-auth-scan"
  | "unauthorized"
  | "forbidden"
  | "upload-blocked"
  | "multiple-faces"
  | "no-face"
  | "cancelled"
  | "scan-failed";

interface ScanFlowErrorOptions {
  status?: number;
  reopenPhotoHelp?: boolean;
}

export class ScanFlowError extends Error {
  readonly code: ScanFlowErrorCode;
  readonly status?: number;
  readonly reopenPhotoHelp: boolean;

  constructor(code: ScanFlowErrorCode, message: string, options: ScanFlowErrorOptions = {}) {
    super(message);
    this.name = "ScanFlowError";
    this.code = code;
    this.status = options.status;
    this.reopenPhotoHelp = options.reopenPhotoHelp ?? false;
  }
}

export function createMissingUploadAuthError() {
  return new ScanFlowError("missing-auth-upload", "You must be signed in to upload.");
}

export function createMissingScanAuthError() {
  return new ScanFlowError(
    "missing-auth-scan",
    "You must be signed in to start a face scan.",
  );
}

function extractMessage(error: unknown) {
  if (typeof error === "string") {
    return error;
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  if (error && typeof error === "object") {
    const message = Reflect.get(error, "message");
    if (typeof message === "string" && message.trim().length > 0) {
      return message;
    }
  }

  return "";
}

function extractStatus(error: unknown) {
  if (!error || typeof error !== "object") {
    return undefined;
  }

  const status = Reflect.get(error, "status");
  return typeof status === "number" ? status : undefined;
}

export function isAbortLikeError(error: unknown) {
  if (error instanceof DOMException && error.name === "AbortError") {
    return true;
  }

  if (error && typeof error === "object") {
    const code = Reflect.get(error, "code");
    const name = Reflect.get(error, "name");
    return code === "storage/canceled" || name === "AbortError";
  }

  return false;
}

export function toScanFlowError(error: unknown): ScanFlowError {
  if (error instanceof ScanFlowError) {
    return error;
  }

  if (isAbortLikeError(error)) {
    return new ScanFlowError("cancelled", "Scan cancelled.");
  }

  const message = extractMessage(error).trim();
  const status = extractStatus(error);
  const normalized = message.toLowerCase();

  if (status === 401) {
    return new ScanFlowError("unauthorized", "Auth failed: sign in again.", { status });
  }

  if (status === 403) {
    return new ScanFlowError(
      "forbidden",
      "Forbidden: email mismatch with authenticated user.",
      { status },
    );
  }

  if (
    normalized.includes("permission") ||
    normalized.includes("security rules") ||
    normalized.includes("storage/unauthorized")
  ) {
    return new ScanFlowError(
      "upload-blocked",
      "Upload blocked by security rules. Are you signed in and under 10MB?",
    );
  }

  if (
    normalized.includes("multiple faces") ||
    normalized.includes("more than one face")
  ) {
    return new ScanFlowError(
      "multiple-faces",
      "We detected more than one face. Please upload a single-face image.",
      { reopenPhotoHelp: true },
    );
  }

  if (
    normalized.includes("no face") ||
    normalized.includes("couldn't detect a face") ||
    normalized.includes("couldn’t detect a face") ||
    normalized.includes("face not detected")
  ) {
    return new ScanFlowError(
      "no-face",
      "We couldn’t detect a face. Please try again using the photo tips.",
      { reopenPhotoHelp: true },
    );
  }

  return new ScanFlowError(
    "scan-failed",
    "Something went wrong while scanning. Please try again.",
    { status },
  );
}
