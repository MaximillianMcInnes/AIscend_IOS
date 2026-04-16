import { ALLOWED_EXT, ALLOWED_MIME, MAX_BYTES } from "./constants";
import { ScanFlowError } from "./errors";

export function getFileExtension(filename: string) {
  const segments = filename.trim().toLowerCase().split(".");
  return segments.length > 1 ? segments.pop() ?? "" : "";
}

export function validateImageFile(file: File) {
  const extension = getFileExtension(file.name);

  if (!file.type.startsWith("image/")) {
    throw new ScanFlowError("invalid-image-type", "Please upload a JPG or PNG image.");
  }

  if (!ALLOWED_MIME.includes(file.type as (typeof ALLOWED_MIME)[number])) {
    throw new ScanFlowError("invalid-image-type", "Please upload a JPG or PNG image.");
  }

  if (!ALLOWED_EXT.includes(extension as (typeof ALLOWED_EXT)[number])) {
    throw new ScanFlowError("invalid-image-type", "Please upload a JPG or PNG image.");
  }

  if (file.size > MAX_BYTES) {
    throw new ScanFlowError("too-large", "Image must be 10MB or less.");
  }

  return {
    extension: extension as (typeof ALLOWED_EXT)[number],
    contentType: file.type as (typeof ALLOWED_MIME)[number],
  };
}
