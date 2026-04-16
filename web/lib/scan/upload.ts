import type { User } from "firebase/auth";
import {
  getDownloadURL,
  ref,
  uploadBytesResumable,
  type UploadMetadata,
} from "firebase/storage";

import { getFirebaseStorage } from "../firebase/client";
import { createMissingUploadAuthError, toScanFlowError } from "./errors";
import type { ScanImageKind, UploadedScanImage } from "./types";
import { validateImageFile } from "./validation";

interface UploadScanImageArgs {
  user: User | null;
  file: File;
  kind: ScanImageKind;
  signal?: AbortSignal;
}

export async function uploadScanImage({
  user,
  file,
  kind,
  signal,
}: UploadScanImageArgs): Promise<UploadedScanImage> {
  if (!user) {
    throw createMissingUploadAuthError();
  }

  const { extension, contentType } = validateImageFile(file);

  if (signal?.aborted) {
    throw signal.reason ?? new DOMException("Scan cancelled.", "AbortError");
  }

  const storageReference = ref(
    getFirebaseStorage(),
    `users/${user.uid}/uploads/${kind}_${crypto.randomUUID()}.${extension}`,
  );

  const metadata: UploadMetadata = {
    contentType,
    cacheControl: "public, max-age=31536000, immutable",
    customMetadata: {
      uid: user.uid,
      kind,
      originalName: file.name,
    },
  };

  const uploadTask = uploadBytesResumable(storageReference, file, metadata);
  const abortHandler = () => uploadTask.cancel();
  signal?.addEventListener("abort", abortHandler, { once: true });

  try {
    await new Promise<void>((resolve, reject) => {
      uploadTask.on(
        "state_changed",
        undefined,
        (error) => reject(error),
        () => resolve(),
      );
    });

    if (signal?.aborted) {
      throw signal.reason ?? new DOMException("Scan cancelled.", "AbortError");
    }

    const downloadUrl = await getDownloadURL(uploadTask.snapshot.ref);

    return {
      storagePath: uploadTask.snapshot.ref.fullPath,
      downloadUrl,
      ref: uploadTask.snapshot.ref,
      contentType,
    };
  } catch (error) {
    throw toScanFlowError(error);
  } finally {
    signal?.removeEventListener("abort", abortHandler);
  }
}
