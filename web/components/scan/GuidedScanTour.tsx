"use client";

import { AnimatePresence, motion } from "framer-motion";

import styles from "./scan-flow.module.css";

interface GuidedScanTourProps {
  open: boolean;
  onClose: () => void;
  onStart: () => void;
}

const TOUR_STEPS = [
  {
    title: "Front capture",
    body: "Keep the camera level, shoulders relaxed, and expression neutral before you confirm the front image.",
  },
  {
    title: "Side profile",
    body: "Turn to a true profile so the jawline, chin support, and facial balance read cleanly.",
  },
  {
    title: "Premium analysis",
    body: "AIScend uploads both photos, runs the face-scan pipeline, saves the payload, and drops you straight into results.",
  },
] as const;

export function GuidedScanTour({
  open,
  onClose,
  onStart,
}: GuidedScanTourProps) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div
          className={styles.modalBackdrop}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className={styles.modalCard}
            initial={{ opacity: 0, y: 18, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 18, scale: 0.97 }}
            transition={{ duration: 0.22, ease: "easeOut" }}
          >
            <div className={styles.modalHeader}>
              <span className={styles.heroBadge}>Guided scan tour</span>
              <button
                type="button"
                className={styles.modalClose}
                onClick={onClose}
                aria-label="Close guided scan tour"
              >
                Close
              </button>
            </div>

            <h2 className={styles.modalTitle}>First scan? Here’s the short route.</h2>
            <div className={styles.tourList}>
              {TOUR_STEPS.map((step, index) => (
                <div key={step.title} className={styles.tourStep}>
                  <span className={styles.tourIndex}>{index + 1}</span>
                  <div>
                    <strong>{step.title}</strong>
                    <p>{step.body}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className={styles.modalActions}>
              <button type="button" className={styles.primaryButton} onClick={onStart}>
                Start scan
              </button>
              <button type="button" className={styles.secondaryButton} onClick={onClose}>
                Maybe later
              </button>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
