"use client";

import { AnimatePresence, motion } from "framer-motion";

import { PHOTO_GUIDANCE } from "../../lib/scan/constants";
import styles from "./scan-flow.module.css";

interface ScanPhotoHelpProps {
  open: boolean;
  onClose: () => void;
}

export function ScanPhotoHelp({ open, onClose }: ScanPhotoHelpProps) {
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
              <span className={styles.heroBadge}>Photo tips</span>
              <button
                type="button"
                className={styles.modalClose}
                onClick={onClose}
                aria-label="Close photo guidance"
              >
                Close
              </button>
            </div>

            <h2 className={styles.modalTitle}>Give the model cleaner inputs.</h2>
            <p className={styles.modalCopy}>
              If face detection misses, retake the photo using these rules before
              you confirm and scan again.
            </p>

            <div className={styles.tipGrid}>
              {PHOTO_GUIDANCE.map((tip) => (
                <div key={tip} className={styles.tipCard}>
                  <span className={styles.tipDot} />
                  <span>{tip}</span>
                </div>
              ))}
            </div>

            <div className={styles.modalActions}>
              <button type="button" className={styles.primaryButton} onClick={onClose}>
                Got it
              </button>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
