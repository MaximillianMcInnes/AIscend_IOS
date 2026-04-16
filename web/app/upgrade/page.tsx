import Link from "next/link";

import styles from "../../components/scan/scan-flow.module.css";

export default function UpgradePage() {
  return (
    <main className={styles.page}>
      <div className={styles.ambientGlow} />
      <section className={styles.shell}>
        <div className={styles.topBar}>
          <div>
            <p className={styles.stepKicker}>Premium</p>
            <h1 className={styles.stepTitle}>Upgrade AIScend</h1>
          </div>
        </div>

        <article className={styles.card}>
          <div className={styles.heroCopy}>
            <span className={styles.heroBadge}>Premium unlock</span>
            <h2 className={styles.heroHeadline}>
              Deeper scan detail, smoother cadence, stronger archive.
            </h2>
            <p className={styles.heroBody}>
              This placeholder upgrade route is wired in so the scan flow can
              send free users to <code>/upgrade</code> immediately. Swap this
              with your real paywall when you drop the feature into the main web
              app.
            </p>
          </div>

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
