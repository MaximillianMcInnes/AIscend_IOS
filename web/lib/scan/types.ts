import type { StorageReference } from "firebase/storage";

export type ScanStep = "start" | "front" | "side" | "loading";
export type ScanImageKind = "front" | "side";

export interface ScanImageState {
  file: File | null;
  previewUrl: string | null;
  confirmed: boolean;
  error: string | null;
}

export interface UploadedScanImage {
  storagePath: string;
  downloadUrl: string;
  ref: StorageReference;
  contentType: string;
}

export interface FaceScanResponse<TPayload extends Record<string, unknown> = Record<string, unknown>> {
  status: "success" | string;
  uid: string;
  email: string | null;
  subscription: string;
  data: TPayload;
}

export interface SaveScanToFirestoreArgs {
  uid: string;
  email: string | null;
  Scantype: string;
  overallScore: number;
  jsonData: Record<string, unknown>;
  frontImageUrl: string;
  sideImageUrl: string;
}

export interface PersistedLastScanResult {
  payload: Record<string, unknown>;
  meta: {
    frontUrl: string;
    sideUrl: string;
    email: string | null;
    type: string;
    scanId: string;
    source: "scan-flow";
  };
  savedAt: number;
}
