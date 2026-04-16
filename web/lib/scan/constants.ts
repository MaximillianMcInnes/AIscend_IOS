export const MAX_BYTES = 10 * 1024 * 1024;
export const ALLOWED_MIME = ["image/jpeg", "image/png"] as const;
export const ALLOWED_EXT = ["jpg", "jpeg", "png"] as const;
export const UPLOAD_ACCEPT = "image/png,image/jpeg";
export const LAST_SCAN_SESSION_KEY = "aiscend:lastScanResult";
export const BACKEND_BASE_URL =
  process.env.NEXT_PUBLIC_BACKEND_URL?.trim() ||
  "https://aiscend-backend-764650279068.europe-west1.run.app";

export const PHOTO_GUIDANCE = [
  "No glasses, hats, or hands covering the face.",
  "Use a neutral expression.",
  "Aim for soft, even lighting.",
  "Use a true side profile for the side image.",
  "JPG or PNG only.",
  "10MB max file size.",
] as const;

export const SCAN_LOADING_STAGES = [
  "Booting",
  "Loading Models",
  "Optimizing Photos",
  "Uploading",
  "Face Detection",
  "Landmarks",
  "Feature Analysis",
  "Detail Pass",
  "Scoring",
  "Finalizing",
] as const;
