"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { useEffect, useMemo, useState } from "react";

import { readLatestScanResult } from "../../lib/scan/persistence";
import { getOverallScore } from "../../lib/scan/result";
import type { PersistedLastScanResult } from "../../lib/scan/types";
import styles from "./scan-flow.module.css";

export function ScanResultsSessionView() {
  const [result, setResult] = useState<PersistedLastScanResult | null>(null);
  const [hasLoaded, setHasLoaded] = useState(false);

  useEffect(() => {
    setResult(readLatestScanResult());
    setHasLoaded(true);
  }, []);

  const formattedSavedAt = useMemo(() => {
    if (!result) {
      return null;
    }

    return new Date(result.savedAt).toLocaleString();
  }, [result]);

  if (!hasLoaded) {
    return (
      <main className={styles.page}>
        <div className={styles.ambientGlow} />
        <section className={styles.shell}>
          <article className={styles.card}>
            <p className={styles.stepKicker}>Loading</p>
            <h1 className={styles.stepTitle}>Opening your latest scan…</h1>
          </article>
        </section>
      </main>
    );
  }

  if (!result) {
    return (
      <main className={styles.page}>
        <div className={styles.ambientGlow} />
        <section className={styles.shell}>
          <article className={styles.card}>
            <p className={styles.stepKicker}>No session result</p>
            <h1 className={styles.stepTitle}>There isn’t a saved scan result in this session.</h1>
            <p className={styles.stepBody}>
              Run a scan first and the latest payload will be persisted under
              <code> aiscend:lastScanResult</code>.
            </p>
            <div className={styles.actionColumn}>
              <Link href="/scan" className={styles.primaryButton}>
                Back to scan
              </Link>
            </div>
          </article>
        </section>
      </main>
    );
  }

  const overallScore = getOverallScore(result.payload, 5);

  return (
    <main className={styles.page}>
      <div className={styles.ambientGlow} />
      <section className={styles.shell}>
        <div className={styles.topBar}>
          <div>
            <p className={styles.stepKicker}>Latest scan</p>
            <h1 className={styles.stepTitle}>AIScend results session</h1>
          </div>
          <Link href="/scan" className={styles.secondaryButton}>
            New scan
          </Link>
        </div>

        <motion.article
          className={styles.card}
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.24, ease: "easeOut" }}
        >
          <div className={styles.resultsHero}>
            <div>
              <span className={styles.heroBadge}>Saved to session</span>
              <h2 className={styles.heroHeadline}>{overallScore.toFixed(1)} overall</h2>
              <p className={styles.heroBody}>
                Source: {result.meta.source} · Type: {result.meta.type}
              </p>
            </div>

            <div className={styles.statStack}>
              <div className={styles.statPill}>
                <span>Scan ID</span>
                <strong>{result.meta.scanId}</strong>
              </div>
              <div className={styles.statPill}>
                <span>Saved at</span>
                <strong>{formattedSavedAt}</strong>
              </div>
            </div>
          </div>

          <div className={styles.previewGrid}>
            <div className={styles.previewPanel}>
              <span className={styles.previewLabel}>Front</span>
              <img
                src={result.meta.frontUrl}
                alt="Front scan upload"
                className={styles.previewImage}
              />
            </div>
            <div className={styles.previewPanel}>
              <span className={styles.previewLabel}>Side</span>
              <img
                src={result.meta.sideUrl}
                alt="Side scan upload"
                className={styles.previewImage}
              />
            </div>
          </div>

          <div className={styles.jsonCard}>
            <span className={styles.previewLabel}>Backend payload</span>
            <pre className={styles.jsonBlock}>
              {JSON.stringify(result.payload, null, 2)}
            </pre>
          </div>
        </motion.article>
      </section>
    </main>
  );
}
