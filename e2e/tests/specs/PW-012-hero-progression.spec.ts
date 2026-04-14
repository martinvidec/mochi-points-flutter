/**
 * PW-012 — Hero-Progression (XP, Level-Up)
 *
 * Source spec: docs/tests/playwright/PW-012-hero-progression.md
 * IST-Analyse process: P8
 * Tracking issue: #176
 *
 * Covers the hero card display and XP/level mechanics:
 *   - Hero card shows level + title + XP-to-next-level
 *   - XP grows after a parent quest approval
 *   - Level-up triggers at threshold crossing (carry-over semantics)
 *
 * Setup for XP-changing tests uses the same B-7 workaround as PW-007
 * TC-007.6: start as child first so hero-home runs
 * `heroProvider.loadData()`, then switch to parent to approve the quest.
 * Otherwise `heroProvider.addXP()` no-ops on a null hero and XP is never
 * credited.
 *
 * Semantics findings:
 *   - Hero card accessible name pattern (F-12):
 *     "<Initial> <Name> Level <N> <Title> XP <current> / <nextLevelThreshold>"
 *     Title at level ≤ 10 is "Mochi Novice"; threshold derives from
 *     `100 + (level-1) * 50` → Level 1→2 = 100, Level 2→3 = 150, …
 *   - Level-up animation runs as a canvas overlay, text not in semantics
 *     tree (F-31) — we verify level change via localStorage.
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterText } from '../fixtures/flutter';
import {
  seedFamilyWithQuestAndReward,
  IDS,
  type SeedPayload,
} from '../fixtures/seed';

/** Base: pending quest + child logged in (so hero-home loads heroProvider). */
function seedPendingQuestChildFirst(): SeedPayload {
  const base = seedFamilyWithQuestAndReward();
  const now = new Date().toISOString();
  return {
    ...base,
    lastUserId: IDS.childLucaId,
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

/** Seed where Luca is at XP 60/100 — approving (50 XP quest) triggers
 *  a level-up with carry-over: level 1 → 2, currentXP 60 + 50 − 100 = 10. */
function seedNearLevelUpChildFirst(): SeedPayload {
  const base = seedPendingQuestChildFirst();
  return {
    ...base,
    heroes: [
      {
        id: IDS.heroLucaId,
        userId: IDS.childLucaId,
        name: 'Luca',
        level: 1,
        currentXP: 60,
        xpToNextLevel: 100,
        currentStreak: 0,
        longestStreak: 0,
        activityDates: [],
        lastActiveDate: null,
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
  };
}

/** Log out the current user and log in as parent Mama (PIN 1234). */
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

/** Log out the current user and log in as child Luca (no PIN). */
async function switchToChild(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page
    .getByRole('button', { name: /abmelden.*ausloggen/i })
    .click();
  await expect(page).toHaveURL(/#\/login/);
  await page.getByRole('button', { name: /luca.*kind/i }).click();
  await expect(page).toHaveURL(/#\/hero-home/);
}

/** As parent (on the dashboard), approve the pending quest. */
async function parentApproveQuest(page: Page): Promise<void> {
  await page.getByRole('button', { name: /\bapprove$/i }).click();
  await expect(
    page.getByRole('heading', { name: /freigabe/i }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Bestätigen' }).click();
  await expect(flutterText(page, /quest bestätigt/i)).toBeVisible();
}

/** Dismiss the level-up dialog if it appears. Per F-31, the "LEVEL UP!"
 *  text is canvas-painted and not reliably in semantics — we tap-to-
 *  dismiss or click "Weiter" if present. */
async function dismissLevelUpIfPresent(page: Page): Promise<void> {
  const weiter = page.getByRole('button', { name: /weiter/i });
  try {
    await weiter.waitFor({ state: 'visible', timeout: 5000 });
    await weiter.click();
  } catch {
    await page.mouse.click(400, 400);
  }
}

test.describe('PW-012 Hero-Progression', () => {
  test('TC-012.1 — Hero-Karte zeigt Level, Titel und XP-Format', async ({
    seededPage,
  }) => {
    // Child logged in from seed, hero starts at level 1, XP 0/100.
    const page = await seededPage(seedPendingQuestChildFirst());

    // Hero card accessible name follows F-12 pattern.
    await expect(
      page.getByRole('button', {
        name: /luca.*level\s*1.*mochi novice.*xp\s*0\s*\/\s*100/i,
      }),
    ).toBeVisible();
  });

  test('TC-012.2 — XP steigt nach Quest-Approval', async ({ seededPage }) => {
    const page = await seededPage(seedPendingQuestChildFirst());

    // Child is logged in — hero-home runs heroProvider.loadData().
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Switch to parent, approve quest (+50 XP)
    await switchToParent(page);
    await parentApproveQuest(page);

    // Back to child to re-render hero-home with updated hero state
    await switchToChild(page);

    // XP bar now shows 50/100 at the same level / title
    await expect(
      page.getByRole('button', {
        name: /luca.*level\s*1.*mochi novice.*xp\s*50\s*\/\s*100/i,
      }),
    ).toBeVisible();

    // Verify persisted hero state
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.heroes'),
    );
    const heroes = JSON.parse(JSON.parse(raw!));
    expect(heroes[0].level).toBe(1);
    expect(heroes[0].currentXP).toBe(50);
  });

  test('TC-012.3 — Level-Up ausgelöst + Notification', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedNearLevelUpChildFirst());

    // Child loads — this is needed for heroProvider to know the hero
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);

    // Level-up dialog might appear in the parent view — dismiss it if so
    await dismissLevelUpIfPresent(page);

    // Verify hero level in localStorage
    const heroRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.heroes'),
    );
    const heroes = JSON.parse(JSON.parse(heroRaw!));
    expect(heroes[0].level).toBe(2);

    // Verify level-up notification for the child
    const nRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(nRaw!));
    const levelUpNotif = notifications.find(
      (n: { type: string }) => n.type === 'levelUp',
    );
    expect(levelUpNotif).toBeTruthy();
    expect(levelUpNotif.userId).toBe(IDS.childLucaId);
  });

  test('TC-012.4 — Level-Up-Overflow: Rest-XP wird ins neue Level übertragen',
      async ({ seededPage }) => {
    // Seed: Luca at 60 XP, threshold 100. Approving 50 XP → 110 → level 2
    // with currentXP = 10. LevelService says next threshold is 150.
    const page = await seededPage(seedNearLevelUpChildFirst());

    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await switchToParent(page);
    await parentApproveQuest(page);
    await dismissLevelUpIfPresent(page);

    // Switch to child to see the updated hero card
    await switchToChild(page);

    // Hero now at Level 2 with 10 XP toward 150-threshold.
    await expect(
      page.getByRole('button', {
        name: /luca.*level\s*2.*mochi novice.*xp\s*10\s*\/\s*150/i,
      }),
    ).toBeVisible();

    // Authoritative check via localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.heroes'),
    );
    const heroes = JSON.parse(JSON.parse(raw!));
    expect(heroes[0].level).toBe(2);
    expect(heroes[0].currentXP).toBe(10);
    expect(heroes[0].xpToNextLevel).toBe(150);
  });
});
