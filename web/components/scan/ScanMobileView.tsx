"use client";

import { AnimatePresence, motion } from "framer-motion";
import { startTransition, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";

import { useAuthSession } from "../../hooks/useAuthSession";
import { useUserProfile } from "../../hooks/useUserProfile";
import {
  PHOTO_GUIDANCE,
  SCAN_LOADING_STAGES,
  UPLOAD_ACCEPT,
} from "../../lib/scan/constants";
import { startFaceScan } from "../../lib/scan/api";
import {
  createMissingScanAuthError,
  toScanFlowError,
} from "../../lib/scan/errors";
import {
  decrementUserScanBalance,
  saveScanToFirestore,
} from "../../lib/scan/firestore";
import { persistLatestScanResult } from "../../lib/scan/persistence";
import { asRecord, getOverallScore } from "../../lib/scan/result";
import type { ScanImageKind, ScanImageState, ScanStep } from "../../lib/scan/types";
import { uploadScanImage } from "../../lib/scan/upload";
import { validateImageFile } from "../../lib/scan/validation";
import { GuidedScanTour } from "./GuidedScanTour";
import { PremiumUpsellPopup } from "./PremiumUpsellPopup";
import { ScanLoadingPage } from "./ScanLoadingPage";
import { ScanPhotoHelp } from "./ScanPhotoHelp";
import styles from "./scan-flow.module.css";

const EMPTY_IMAGE_STATE: ScanImageState = {
  file: null,
  previewUrl: null,
  confirmed: false,
  error: null,
};

function sleep(durationMs: number) {
  return new Promise<void>((resolve) => {
    window.setTimeout(resolve, durationMs);
  });
}

function isPaidSubscription(subscription: string) {
  const normalized = subscription.trim().toLowerCase();
  return ["premium", "pro", "paid", "active", "trialing"].some((value) =>
    normalized.includes(value),
  );
}

function formatSubscription(subscription: string) {
  if (!subscription) {
    return "Free";
  }

  return subscription.charAt(0).toUpperCase() + subscription.slice(1);
}

export function ScanMobileView() {
  const router = useRouter();
  const { user, isLoading: authLoading, error: authError } = useAuthSession();
  const {
    profile,
    isLoading: profileLoading,
    error: profileError,
    refreshProfile,
  } = useUserProfile(user);

  const [step, setStep] = useState<ScanStep>("start");
  const [frontImage, setFrontImage] = useState<ScanImageState>(EMPTY_IMAGE_STATE);
  const [sideImage, setSideImage] = useState<ScanImageState>(EMPTY_IMAGE_STATE);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showUpsell, setShowUpsell] = useState(false);
  const [showPhotoHelp, setShowPhotoHelp] = useState(false);
  const [showGuidedTour, setShowGuidedTour] = useState(false);
  const [loadingStageIndex, setLoadingStageIndex] = useState(0);
  const [loadingProgress, setLoadingProgress] = useState(0);

  const frontInputRef = useRef<HTMLInputElement | null>(null);
  const sideInputRef = useRef<HTMLInputElement | null>(null);
  const abortRef = useRef<AbortController | null>(null);
  const progressIntervalRef = useRef<number | null>(null);

  const subscription = profile?.subscription?.trim() || "free";
  const normalizedSubscription = subscription.toLowerCase();
  const isPaidUser = isPaidSubscription(normalizedSubscription);
  const scansLeft = profile?.scansLeft ?? 0;
  const hasScannedBefore = Boolean(profile?.Scanned || profile?.Scaned);
  const isLoadingStep = step === "loading";

  const etaLabel = useMemo(() => {
    const remainingStages = Math.max(SCAN_LOADING_STAGES.length - loadingStageIndex, 1);
    const seconds = Math.max(remainingStages * 3, 6);
    return `~${seconds}s`;
  }, [loadingStageIndex]);

  useEffect(() => {
    router.prefetch("/scan/results");
    router.prefetch("/upgrade");
  }, [router]);

  useEffect(() => {
    if (!user || profileLoading || hasScannedBefore) {
      return;
    }

    try {
      const storageKey = `aiscend:guided-scan-tour:${user.uid}`;
      const hasSeenTour = window.sessionStorage.getItem(storageKey);
      if (!hasSeenTour) {
        setShowGuidedTour(true);
      }
    } catch {
      setShowGuidedTour(true);
    }
  }, [user, profileLoading, hasScannedBefore]);

  useEffect(() => {
    const previewUrl = frontImage.previewUrl;

    if (!previewUrl) {
      return undefined;
    }

    return () => {
      URL.revokeObjectURL(previewUrl);
    };
  }, [frontImage.previewUrl]);

  useEffect(() => {
    const previewUrl = sideImage.previewUrl;

    if (!previewUrl) {
      return undefined;
    }

    return () => {
      URL.revokeObjectURL(previewUrl);
    };
  }, [sideImage.previewUrl]);

  useEffect(() => {
    return () => {
      abortRef.current?.abort();

      if (progressIntervalRef.current) {
        window.clearInterval(progressIntervalRef.current);
      }
    };
  }, []);

  function clearProgressLoop() {
    if (progressIntervalRef.current) {
      window.clearInterval(progressIntervalRef.current);
      progressIntervalRef.current = null;
    }
  }

  function beginProgressLoop() {
    clearProgressLoop();
    setLoadingStageIndex(0);
    setLoadingProgress(6);

    progressIntervalRef.current = window.setInterval(() => {
      setLoadingStageIndex((current) =>
        Math.min(current + 1, SCAN_LOADING_STAGES.length - 2),
      );
      setLoadingProgress((current) => Math.min(current + 8, 92));
    }, 900);
  }

  function updateImageState(
    kind: ScanImageKind,
    updater: (previous: ScanImageState) => ScanImageState,
  ) {
    const setter = kind === "front" ? setFrontImage : setSideImage;

    setter((previous) => {
      const next = updater(previous);
      if (previous.previewUrl && previous.previewUrl !== next.previewUrl) {
        URL.revokeObjectURL(previous.previewUrl);
      }
      return next;
    });
  }

  function openPicker(kind: ScanImageKind) {
    if (kind === "front") {
      frontInputRef.current?.click();
      return;
    }

    sideInputRef.current?.click();
  }

  function handleFileSelection(kind: ScanImageKind, file: File | null) {
    if (!file) {
      return;
    }

    try {
      validateImageFile(file);
      const previewUrl = URL.createObjectURL(file);

      updateImageState(kind, () => ({
        file,
        previewUrl,
        confirmed: false,
        error: null,
      }));

      setErrorMessage(null);
    } catch (error) {
      const nextError = toScanFlowError(error);
      updateImageState(kind, () => ({
        file: null,
        previewUrl: null,
        confirmed: false,
        error: nextError.message,
      }));
      setErrorMessage(nextError.message);
    }
  }

  function handleStartScan() {
    setErrorMessage(null);
    setStep("front");
  }

  function handleFrontConfirm() {
    if (!frontImage.file) {
      setErrorMessage("Please upload a JPG or PNG image.");
      return;
    }

    setFrontImage((previous) => ({
      ...previous,
      confirmed: true,
      error: null,
    }));
    setErrorMessage(null);
    setStep("side");
  }

  function handleSideBack() {
    setSideImage((previous) => ({
      ...previous,
      confirmed: false,
    }));
    setErrorMessage(null);
    setStep("front");
  }

  function rememberTourDismissal() {
    if (!user) {
      return;
    }

    try {
      window.sessionStorage.setItem(`aiscend:guided-scan-tour:${user.uid}`, "1");
    } catch {
      // ignore storage failures
    }
  }

  async function runScan() {
    if (!frontImage.file || !sideImage.file) {
      setErrorMessage("Please upload a JPG or PNG image.");
      setStep("side");
      return;
    }

    if (!user) {
      const missingAuthError = createMissingScanAuthError();
      setErrorMessage(missingAuthError.message);
      setStep("side");
      return;
    }

    setShowUpsell(false);
    setErrorMessage(null);
    setStep("loading");

    const controller = new AbortController();
    abortRef.current = controller;
    beginProgressLoop();

    try {
      setSideImage((previous) => ({
        ...previous,
        confirmed: true,
      }));

      const frontUpload = await uploadScanImage({
        user,
        file: frontImage.file,
        kind: "front",
        signal: controller.signal,
      });

      setLoadingStageIndex(3);
      setLoadingProgress(32);

      const sideUpload = await uploadScanImage({
        user,
        file: sideImage.file,
        kind: "side",
        signal: controller.signal,
      });

      setLoadingStageIndex(4);
      setLoadingProgress(48);

      const result = await startFaceScan<Record<string, unknown>>({
        user,
        frontSource: frontUpload.storagePath,
        sideSource: sideUpload.storagePath,
        email: user.email ?? profile?.email ?? null,
        subscription: normalizedSubscription,
        signal: controller.signal,
      });

      setLoadingStageIndex(8);
      setLoadingProgress(82);

      const payload = asRecord(result.data);
      const overallScore = getOverallScore(payload, 5.0);

      const { scanId } = await saveScanToFirestore({
        uid: user.uid,
        email: user.email ?? profile?.email ?? null,
        Scantype: normalizedSubscription,
        overallScore,
        jsonData: payload,
        frontImageUrl: frontUpload.downloadUrl,
        sideImageUrl: sideUpload.downloadUrl,
      });

      setLoadingStageIndex(9);
      setLoadingProgress(94);

      await decrementUserScanBalance({
        user,
        currentScansLeft: profile?.scansLeft,
      });

      await refreshProfile();

      persistLatestScanResult({
        payload,
        meta: {
          frontUrl: frontUpload.downloadUrl,
          sideUrl: sideUpload.downloadUrl,
          email: user.email ?? profile?.email ?? null,
          type: normalizedSubscription,
          scanId,
          source: "scan-flow",
        },
        savedAt: Date.now(),
      });

      clearProgressLoop();
      setLoadingStageIndex(SCAN_LOADING_STAGES.length - 1);
      setLoadingProgress(100);
      await sleep(320);

      startTransition(() => {
        router.push("/scan/results");
      });
    } catch (error) {
      const nextError = toScanFlowError(error);
      setSideImage((previous) => ({
        ...previous,
        confirmed: false,
      }));
      setErrorMessage(nextError.message);
      if (nextError.reopenPhotoHelp) {
        setShowPhotoHelp(true);
      }
      setStep("side");
    } finally {
      clearProgressLoop();
      abortRef.current = null;
    }
  }

  function handleSideConfirm() {
    if (!sideImage.file) {
      setErrorMessage("Please upload a JPG or PNG image.");
      return;
    }

    setSideImage((previous) => ({
      ...previous,
      confirmed: true,
      error: null,
    }));
    setErrorMessage(null);

    if (!user) {
      const missingAuthError = createMissingScanAuthError();
      setErrorMessage(missingAuthError.message);
      return;
    }

    if (!isPaidUser) {
      setShowUpsell(true);
      return;
    }

    void runScan();
  }

  function handleCancelScan() {
    abortRef.current?.abort(new DOMException("Scan cancelled.", "AbortError"));
  }

  const startStep = (
    <motion.section
      key="start"
      className={styles.card}
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -18 }}
      transition={{ duration: 0.26, ease: "easeOut" }}
    >
      <div className={styles.heroCopy}>
        <span className={styles.heroBadge}>Premium face scan</span>
        <h1 className={styles.heroHeadline}>Capture a clean front and side baseline.</h1>
        <p className={styles.heroBody}>
          This flow keeps uploads strict, runs the backend analysis contract as-is,
          saves the scan payload to Firestore, and drops the result into the
          session for <code>/scan/results</code>.
        </p>
      </div>

      <div className={styles.statStack}>
        <div className={styles.statPill}>
          <span>Scan balance</span>
          <strong>{profileLoading ? "Loading…" : scansLeft}</strong>
        </div>
        <div className={styles.statPill}>
          <span>Subscription</span>
          <strong>{formatSubscription(subscription)}</strong>
        </div>
      </div>

      <div className={styles.guidanceList}>
        {PHOTO_GUIDANCE.map((tip) => (
          <div key={tip} className={styles.guidanceItem}>
            <span className={styles.guidanceDot} />
            <span>{tip}</span>
          </div>
        ))}
      </div>

      <div className={styles.actionColumn}>
        <button type="button" className={styles.primaryButton} onClick={handleStartScan}>
          Start scan
        </button>
        <button
          type="button"
          className={styles.secondaryButton}
          onClick={() => setShowPhotoHelp(true)}
        >
          Photo tips
        </button>
      </div>
    </motion.section>
  );

  function renderUploadStep(
    kind: ScanImageKind,
    state: ScanImageState,
    heading: string,
    body: string,
    onConfirm: () => void,
    onBack: () => void,
  ) {
    return (
      <motion.section
        key={kind}
        className={styles.card}
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -18 }}
        transition={{ duration: 0.26, ease: "easeOut" }}
      >
        <div className={styles.heroCopy}>
          <span className={styles.heroBadge}>{kind === "front" ? "Step 1" : "Step 2"}</span>
          <h1 className={styles.heroHeadline}>{heading}</h1>
          <p className={styles.heroBody}>{body}</p>
        </div>

        <div className={styles.uploadCard}>
          {state.previewUrl ? (
            <div className={styles.previewFrame}>
              <img
                src={state.previewUrl}
                alt={kind === "front" ? "Front upload preview" : "Side upload preview"}
                className={styles.previewImage}
              />
            </div>
          ) : (
            <button
              type="button"
              className={styles.uploadEmpty}
              onClick={() => openPicker(kind)}
            >
              <span className={styles.uploadLabel}>Choose {kind} photo</span>
              <span className={styles.uploadMeta}>
                Native picker only · JPG or PNG · 10MB max
              </span>
            </button>
          )}

          <input
            ref={kind === "front" ? frontInputRef : sideInputRef}
            type="file"
            accept={UPLOAD_ACCEPT}
            className={styles.fileInput}
            onChange={(event) => {
              handleFileSelection(kind, event.target.files?.[0] ?? null);
              event.currentTarget.value = "";
            }}
          />

          <div className={styles.inlineMeta}>
            <span>3:4 preview</span>
            <span>{state.file?.name ?? "No file selected"}</span>
          </div>
        </div>

        <div className={styles.actionColumn}>
          {state.previewUrl ? (
            <>
              <button type="button" className={styles.primaryButton} onClick={onConfirm}>
                {kind === "front" ? "Confirm & next" : "Confirm & scan"}
              </button>
              <button
                type="button"
                className={styles.secondaryButton}
                onClick={() => openPicker(kind)}
              >
                Replace
              </button>
            </>
          ) : (
            <button
              type="button"
              className={styles.primaryButton}
              onClick={() => openPicker(kind)}
            >
              Upload {kind} photo
            </button>
          )}
          <button type="button" className={styles.tertiaryButton} onClick={onBack}>
            Back
          </button>
        </div>
      </motion.section>
    );
  }

  return (
    <main className={styles.page}>
      <div className={styles.ambientGlow} />

      <section className={styles.shell}>
        {!isLoadingStep && (
          <>
            <div className={styles.topBar}>
              <div>
                <p className={styles.stepKicker}>AIScend scan flow</p>
                <h1 className={styles.stepTitle}>Mobile-first face scan</h1>
              </div>
              <button
                type="button"
                className={styles.ghostButton}
                onClick={() => setShowPhotoHelp(true)}
              >
                Help
              </button>
            </div>

            {(authError || profileError || errorMessage) && (
              <div className={styles.errorBanner}>
                {errorMessage || profileError || authError}
              </div>
            )}

            {!authLoading && !user && (
              <div className={styles.noticeBanner}>
                Sign in is required before upload and scan requests can complete.
              </div>
            )}
          </>
        )}

        <AnimatePresence mode="wait">
          {step === "start" && startStep}

          {step === "front" &&
            renderUploadStep(
              "front",
              frontImage,
              "Upload your front-facing image first.",
              "Use a clean, front-facing photo with neutral expression and even lighting before you confirm.",
              handleFrontConfirm,
              () => {
                setErrorMessage(null);
                setStep("start");
              },
            )}

          {step === "side" &&
            renderUploadStep(
              "side",
              sideImage,
              "Upload your side profile second.",
              "Use a true side profile so the backend can read structure accurately before you start the scan.",
              handleSideConfirm,
              handleSideBack,
            )}

          {step === "loading" && (
            <ScanLoadingPage
              key="loading"
              progress={loadingProgress}
              stageIndex={loadingStageIndex}
              etaLabel={etaLabel}
              onCancel={handleCancelScan}
            />
          )}
        </AnimatePresence>
      </section>

      <PremiumUpsellPopup
        open={showUpsell}
        scansLeft={scansLeft}
        onContinue={() => {
          setShowUpsell(false);
          void runScan();
        }}
        onUpgrade={() => {
          setShowUpsell(false);
          startTransition(() => {
            router.push("/upgrade");
          });
        }}
      />

      <ScanPhotoHelp open={showPhotoHelp} onClose={() => setShowPhotoHelp(false)} />

      <GuidedScanTour
        open={showGuidedTour}
        onClose={() => {
          rememberTourDismissal();
          setShowGuidedTour(false);
        }}
        onStart={() => {
          rememberTourDismissal();
          setShowGuidedTour(false);
          setStep("front");
        }}
      />
    </main>
  );
}
