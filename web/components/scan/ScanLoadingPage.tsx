"use client";

import { motion } from "framer-motion";

import { SCAN_LOADING_STAGES } from "../../lib/scan/constants";
import styles from "./scan-flow.module.css";

interface ScanLoadingPageProps {
  progress: number;
  stageIndex: number;
  etaLabel: string;
  onCancel: () => void;
}

export function ScanLoadingPage({
  progress,
  stageIndex,
  etaLabel,
  onCancel,
}: ScanLoadingPageProps) {
  const clampedIndex = Math.min(stageIndex, SCAN_LOADING_STAGES.length - 1);
  const currentStage = SCAN_LOADING_STAGES[clampedIndex];

  return (
    <motion.section
      className={styles.loadingPage}
      initial={{ opacity: 0, y: 22 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -18 }}
      transition={{ duration: 0.28, ease: "easeOut" }}
    >
      <div className={styles.loadingHalo} />

      <div className={styles.loadingHeader}>
        <span className={styles.heroBadge}>AIScend analysis engine</span>
        <h1 className={styles.loadingTitle}>{currentStage}</h1>
        <p className={styles.loadingCopy}>
          Running the premium face-scan pipeline with front and side inputs.
        </p>
      </div>

      <div className={styles.loadingStats}>
        <div className={styles.loadingStat}>
          <span>Progress</span>
          <strong>{Math.round(progress)}%</strong>
        </div>
        <div className={styles.loadingStat}>
          <span>ETA</span>
          <strong>{etaLabel}</strong>
        </div>
      </div>

      <div className={styles.progressRail} aria-hidden="true">
        <motion.div
          className={styles.progressFill}
          animate={{ width: `${Math.max(progress, 4)}%` }}
          transition={{ ease: "easeOut", duration: 0.4 }}
        />
      </div>

      <div className={styles.stageList} aria-live="polite">
        {SCAN_LOADING_STAGES.map((stage, index) => {
          const status =
            index < clampedIndex ? "complete" : index === clampedIndex ? "active" : "idle";

          return (
            <div
              key={stage}
              className={`${styles.stageRow} ${
                status === "active"
                  ? styles.stageRowActive
                  : status === "complete"
                    ? styles.stageRowComplete
                    : ""
              }`}
            >
              <span className={styles.stageDot} />
              <span>{stage}</span>
            </div>
          );
        })}
      </div>

      <button type="button" className={styles.cancelButton} onClick={onCancel}>
        Cancel scan
      </button>
    </motion.section>
  );
}
