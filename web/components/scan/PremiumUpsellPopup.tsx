"use client";

import { AnimatePresence, motion } from "framer-motion";

import styles from "./scan-flow.module.css";

interface PremiumUpsellPopupProps {
  open: boolean;
  scansLeft: number;
  onContinue: () => void;
  onUpgrade: () => void;
}

export function PremiumUpsellPopup({
  open,
  scansLeft,
  onContinue,
  onUpgrade,
}: PremiumUpsellPopupProps) {
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
              <span className={styles.heroBadge}>Premium unlock</span>
              <button
                type="button"
                className={styles.modalClose}
                onClick={onContinue}
                aria-label="Continue with scan"
              >
                Continue
              </button>
            </div>

            <h2 className={styles.modalTitle}>Go premium for deeper scan detail.</h2>
            <p className={styles.modalCopy}>
              Premium keeps the scan loop faster and unlocks the sharper report
              layer. You still have {scansLeft} scan{scansLeft === 1 ? "" : "s"} left
              on this account.
            </p>

            <div className={styles.modalActions}>
              <button type="button" className={styles.primaryButton} onClick={onUpgrade}>
                Upgrade
              </button>
              <button type="button" className={styles.secondaryButton} onClick={onContinue}>
                Continue with free scan
              </button>
            </div>
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}
