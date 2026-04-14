/**
 * PW-014 — Streak-Anzeige & Bonus
 *
 * Source spec: docs/tests/playwright/PW-014-streak-bonus.md
 * IST-Analyse process: P9
 * Tracking issue: #178
 *
 * Covers streak mechanics triggered by quest approval:
 *   - First approval sets streak to 1
 *   - Consecutive-day approval grows the streak
 *   - 7+ day streak produces a points bonus on approval
 *   - Crossing a milestone (7) triggers a streakMilestone notification
 *
 * Time strategy: instead of manipulating the JS clock (fragile on
 * Flutter Web where DateTime.now crosses the Dart/JS boundary), seed
 * `activityDates` + `currentStreak` relative to the actual test run
 * date. The app's `recordActivity()` uses `DateTime.now()` naturally.
 *
 * Setup: B-7 workaround — child session first (so hero-home runs
 * heroProvider.loadData), then switch to parent to approve.
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterText } from '../fixtures/flutter';
import {
  seedFamilyWithQuestAndReward,
  IDS,
  type SeedPayload,
} from '../fixtures/seed';

/** ISO date-strings for the previous `n` days, newest-first
 *  (e.g. `datesBack(3)` returns [yesterday, dayBefore, threeDaysAgo]).
 *
 *  Important timezone subtlety: Dart deserialises via `DateTime.parse`
 *  which returns a UTC DateTime, and `StreakService.calculateStreak`
 *  normalises with `DateTime(d.year, d.month, d.day)` using the UTC
 *  date components. If we emit local-midnight ISO strings, the UTC
 *  components may land on the previous calendar day depending on the
 *  host timezone, which skews the streak by one.
 *
 *  Fix: anchor each date at **12:00 UTC** — noon UTC is the same
 *  calendar day in every timezone from UTC-12 to UTC+12, so both the
 *  seeded UTC components and the local-today components stay aligned
 *  with the intended day. */
function datesBack(n: number): string[] {
  const out: string[] = [];
  const today = new Date();
  for (let i = 1; i <= n; i++) {
    const d = new Date(
      Date.UTC(today.getFullYear(), today.getMonth(), today.getDate() - i, 12),
    );
    out.push(d.toISOString());
  }
  return out;
}

/** Seed with a pending quest, Luca logged in (hero-home loads provider). */
function seedPendingQuestChildFirst(
  overrides: {
    currentStreak?: number;
    longestStreak?: number;
    activityDates?: string[];
    lastActiveDate?: string | null;
  } = {},
): SeedPayload {
  const base = seedFamilyWithQuestAndReward();
  const now = new Date().toISOString();
  return {
    ...base,
    lastUserId: IDS.childLucaId,
    heroes: [
      {
        id: IDS.heroLucaId,
        userId: IDS.childLucaId,
        name: 'Luca',
        level: 1,
        currentXP: 0,
        xpToNextLevel: 100,
        currentStreak: overrides.currentStreak ?? 0,
        longestStreak: overrides.longestStreak ?? 0,
        activityDates: overrides.activityDates ?? [],
        lastActiveDate: overrides.lastActiveDate ?? null,
        badges: [],
        unlockedItems: [],
        equippedItems: [],
        appearance: {
          baseAvatar: 'default',
          skinColor: 'light',
          hairStyle: 'short',
          hairColor: 'brown',
          outfit: 'casual',
        },
      },
    ],
    questInstances: [
      {
        id: 'qi-seed-001',
        questId: IDS.questCleanRoomId,
        childId: IDS.childLucaId,
        status: 'pendingApproval',
        progress: 1,
        target: 1,
        currentStreak: 0,
        startedAt: now,
        completedAt: now,
        approvedAt: null,
        approvedBy: null,
        createdAt: now,
      },
    ],
  };
}

async function switchToParent(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page
    .getByRole('button', { name: /abmelden.*ausloggen/i })
    .click();
  await expect(page).toHaveURL(/#\/login/);
  await page.getByRole('button', { name: /mama.*eltern/i }).click();
  await expect(flutterText(page, /pin eingeben/i)).toBeVisible();
  for (const digit of '1234') {
    await page.getByRole('button', { name: digit, exact: true }).click();
  }
  await expect(page).toHaveURL(/#\/parent-dashboard/);
}

async function parentApproveQuest(page: Page): Promise<void> {
  await page.getByRole('button', { name: /\bapprove$/i }).click();
  await expect(
    page.getByRole('heading', { name: /freigabe/i }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Bestätigen' }).click();
  await expect(flutterText(page, /quest bestätigt/i)).toBeVisible();
}

/** Helper: read hero[0] from localStorage. */
async function readHero(page: Page): Promise<Record<string, unknown>> {
  const raw = await page.evaluate(() =>
    window.localStorage.getItem('flutter.heroes'),
  );
  return JSON.parse(JSON.parse(raw!))[0];
}

test.describe('PW-014 Streak-Anzeige & Bonus', () => {
  test('TC-014.1 — Erste Approval setzt currentStreak = 1', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedPendingQuestChildFirst());
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);

    const hero = await readHero(page);
    expect(hero.currentStreak).toBe(1);
    expect(hero.longestStreak).toBe(1);
    expect(hero.lastActiveDate).not.toBeNull();
    expect((hero.activityDates as unknown[]).length).toBe(1);
  });

  test('TC-014.2 — Streak wächst an Folgetagen', async ({ seededPage }) => {
    // Seed: yesterday was active, currentStreak=1. Today's approval → 2.
    const page = await seededPage(
      seedPendingQuestChildFirst({
        currentStreak: 1,
        longestStreak: 1,
        activityDates: datesBack(1), // [yesterday]
        lastActiveDate: datesBack(1)[0],
      }),
    );
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);

    const hero = await readHero(page);
    expect(hero.currentStreak).toBe(2);
    expect(hero.longestStreak).toBe(2);
  });

  test('TC-014.3 — Streak ≥ 7 erzeugt Bonus-Transaktion', async ({
    seededPage,
  }) => {
    // Seed: 7 consecutive days of activity ending yesterday.
    // Today's approval pushes streak to 8 → bonus multiplier 1.1x.
    // 10 MP × 1.1 = 11 → bonus = 1 MP (separate bonus transaction).
    const page = await seededPage(
      seedPendingQuestChildFirst({
        currentStreak: 7,
        longestStreak: 7,
        activityDates: datesBack(7),
        lastActiveDate: datesBack(1)[0],
      }),
    );
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);

    // Hero streak now 8 (7 + today's recordActivity)
    const hero = await readHero(page);
    expect(hero.currentStreak).toBe(8);

    // Two points transactions: base questComplete + bonus
    const txnRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.transactions'),
    );
    const txns = JSON.parse(JSON.parse(txnRaw!));
    const bonusTxn = txns.find((t: { type: string }) => t.type === 'bonus');
    const questTxn = txns.find(
      (t: { type: string }) => t.type === 'questComplete',
    );
    expect(questTxn).toBeTruthy();
    expect(questTxn.amount).toBe(10);
    expect(bonusTxn).toBeTruthy();
    expect(bonusTxn.amount).toBeGreaterThan(0);
    // Both reference the same quest
    expect(bonusTxn.referenceId).toBe(questTxn.referenceId);

    // Balance reflects base + bonus
    const pointsRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.points_accounts'),
    );
    const accounts = JSON.parse(JSON.parse(pointsRaw!));
    expect(accounts[0].balance).toBeGreaterThan(10);
  });

  test('TC-014.4 — Streak-Milestone 7 erzeugt Notification', async ({
    seededPage,
  }) => {
    // Seed: 6 consecutive days. Today's approval crosses milestone 7.
    const page = await seededPage(
      seedPendingQuestChildFirst({
        currentStreak: 6,
        longestStreak: 6,
        activityDates: datesBack(6),
        lastActiveDate: datesBack(1)[0],
      }),
    );
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);

    // Streak is now 7 — milestone crossed
    const hero = await readHero(page);
    expect(hero.currentStreak).toBe(7);

    // streakMilestone notification for Luca exists
    const nRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(nRaw!));
    const milestoneNotif = notifications.find(
      (n: { type: string; userId: string }) =>
        n.type === 'streakMilestone' && n.userId === IDS.childLucaId,
    );
    expect(milestoneNotif).toBeTruthy();
    // Message typically references the milestone number
    expect(milestoneNotif.message).toContain('7');
  });

  test.skip('TC-014.5 — Streak-Verlust (blocked: checkStreak not wired at bootstrap)',
      () => {
    // Per IST-Analyse §5.3, checkStreak is not called on app start.
    // Until the bootstrap wiring exists, this case cannot be verified.
  });
});
