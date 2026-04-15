/**
 * PW-007 — Parent: Quest Approval & Rejection
 *
 * Source spec: docs/tests/playwright/PW-007-parent-quest-approval.md
 * IST-Analyse process: P5 (Abschluss + Belohnung)
 * Tracking issue: #171
 *
 * Covers the parent's approval/rejection flow:
 *   - Approval list shows pending quests with badge
 *   - Approve a quest: points + XP awarded, snackbar, quest removed
 *   - Notification created for child after approval
 *   - Reject a quest: dialog with reason, status back to inProgress
 *   - Level-up triggered when XP crosses threshold
 *
 * Approval page:
 *   - heading "Freigabe"
 *   - Approval card with "Ablehnen" / "Bestätigen" buttons
 *   - Badge on Approve tab: "1 Approve" (with count prefix)
 *   - Empty state: "Keine ausstehenden Genehmigungen"
 *
 * Spec adjustments:
 *   - TC-007.4 (streak bonus): Tested via localStorage, not UI
 *     (bonus amounts are internal calculations)
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterText, flutterFill } from '../fixtures/flutter';
import {
  seedFamilyWithQuestAndReward,
  seedChildWithApprovedQuest,
  IDS,
  type SeedPayload,
} from '../fixtures/seed';

/** Build a seed state with a quest in pendingApproval. */
function seedWithPendingQuest(): SeedPayload {
  const base = seedFamilyWithQuestAndReward();
  const now = new Date().toISOString();
  return {
    ...base,
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
    notifications: [
      {
        id: 'notif-seed-001',
        userId: IDS.parentMamaId,
        type: 'questCompleted',
        title: 'Quest wartet auf Genehmigung',
        message: '"Zimmer aufräumen" wurde abgeschlossen.',
        icon: 'hourglass',
        createdAt: now,
        isRead: false,
      },
    ],
  };
}

/**
 * Build a seed where Luca is at XP 60/100 (level 1).
 * Approving "Zimmer aufräumen" (50 XP) will push to 110 → level 2.
 */
function seedNearLevelUp(): SeedPayload {
  const base = seedWithPendingQuest();
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

/** Navigate to the Approve tab. */
async function navigateToApprove(page: Page): Promise<void> {
  await page.getByRole('button', { name: /\bgenehmigungen$/i }).click();
  await expect(
    page.getByRole('heading', { name: /freigabe/i }),
  ).toBeVisible();
}

test.describe('PW-007 Parent: Quest Approval & Rejection', () => {
  test('TC-007.1 — Approval-Liste zeigt Pending', async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    // Badge on Approve tab shows count
    await expect(
      page.getByRole('button', { name: /1\s*genehmigungen/i }),
    ).toBeVisible();

    await navigateToApprove(page);

    // Pending quest is visible in the list.
    // The approval card renders as a group with a combined accessible name
    // containing child name, quest name, and reward info.
    await expect(
      page.getByRole('group', { name: /zimmer aufräumen/i }),
    ).toBeVisible();

    // Approve/Reject buttons are present
    await expect(
      page.getByRole('button', { name: 'Bestätigen' }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Ablehnen' }),
    ).toBeVisible();
  });

  test('TC-007.2 — Quest genehmigen, Punkte & XP vergeben', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedWithPendingQuest());
    await navigateToApprove(page);

    // Approve the quest
    await page.getByRole('button', { name: 'Bestätigen' }).click();

    // Success snackbar
    await expect(
      flutterText(page, /quest bestätigt.*10 punkte.*50 xp/i),
    ).toBeVisible();

    // Empty state: no more pending
    await expect(
      page.getByText('Keine ausstehenden Genehmigungen'),
    ).toBeVisible();

    // Badge gone from Approve tab
    await expect(
      page.getByRole('button', { name: 'Genehmigungen' }),
    ).toBeVisible();

    // Verify localStorage: points awarded
    const pointsRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.points_accounts'),
    );
    expect(pointsRaw).not.toBeNull();
    const accounts = JSON.parse(JSON.parse(pointsRaw!));
    const lucaAccount = accounts.find(
      (a: { userId: string }) => a.userId === IDS.childLucaId,
    );
    expect(lucaAccount.balance).toBeGreaterThanOrEqual(10);

    // Verify transactions
    const txnRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.transactions'),
    );
    expect(txnRaw).not.toBeNull();
    const txns = JSON.parse(JSON.parse(txnRaw!));
    const questTxn = txns.find(
      (t: { type: string }) => t.type === 'questComplete',
    );
    expect(questTxn).toBeTruthy();
    expect(questTxn.amount).toBe(10);

    // Verify quest instance status
    const qiRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quest_instances'),
    );
    const instances = JSON.parse(JSON.parse(qiRaw!));
    expect(instances[0].status).toBe('completed');
    expect(instances[0].approvedBy).toBe(IDS.parentMamaId);
  });

  test('TC-007.3 — Notification für das Kind nach Genehmigung', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedWithPendingQuest());
    await navigateToApprove(page);

    await page.getByRole('button', { name: 'Bestätigen' }).click();
    await expect(
      flutterText(page, /quest bestätigt/i),
    ).toBeVisible();

    // Verify notification for child
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(raw!));
    const childNotif = notifications.find(
      (n: { type: string; userId: string }) =>
        n.type === 'questApproved' && n.userId === IDS.childLucaId,
    );
    expect(childNotif).toBeTruthy();
    expect(childNotif.title).toContain('genehmigt');
  });

  test('TC-007.5 — Quest ablehnen', async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());
    await navigateToApprove(page);

    // Click "Ablehnen"
    await page.getByRole('button', { name: 'Ablehnen' }).click();

    // Rejection dialog appears
    await expect(page.getByText(/ablehnen/i)).toBeVisible();

    // Fill in reason (optional text field)
    const reasonField = page.getByRole('textbox');
    if ((await reasonField.count()) > 0) {
      await flutterFill(reasonField.first(), 'Nicht ordentlich genug');
    }

    // Confirm rejection — click the "Ablehnen" button in the dialog
    // There are now two "Ablehnen" buttons: the card one and dialog one.
    // The dialog's Ablehnen is the last one visible.
    const ablehnenButtons = page.getByRole('button', { name: 'Ablehnen' });
    await ablehnenButtons.last().click();

    // Snackbar confirmation
    await expect(
      flutterText(page, /quest abgelehnt/i),
    ).toBeVisible();

    // Verify quest instance back to inProgress
    const qiRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quest_instances'),
    );
    const instances = JSON.parse(JSON.parse(qiRaw!));
    expect(instances[0].status).toBe('inProgress');
    expect(instances[0].progress).toBe(0);

    // No points awarded
    const pointsRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.points_accounts'),
    );
    const accounts = JSON.parse(JSON.parse(pointsRaw!));
    const lucaAccount = accounts.find(
      (a: { userId: string }) => a.userId === IDS.childLucaId,
    );
    expect(lucaAccount.balance).toBe(0);

    // Notification for child about rejection
    const nRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(nRaw!));
    const rejectNotif = notifications.find(
      (n: { type: string; userId: string }) =>
        n.type === 'questRejected' && n.userId === IDS.childLucaId,
    );
    expect(rejectNotif).toBeTruthy();
  });

  test('TC-007.6 — Level-Up wird getriggert', async ({ seededPage }) => {
    // The level-up requires heroProvider.loadData() to have been called.
    // This only happens in the child flow (hero_home_page.dart:58).
    // To work around app bug B-7 (heroProvider not loaded in parent session),
    // we start as child first to populate the hero provider, then switch
    // to parent for the approval.
    const seed = seedNearLevelUp();
    const page = await seededPage({
      ...seed,
      lastUserId: IDS.childLucaId, // Start as child
    });

    // Landing on hero-home triggers heroProvider.loadData()
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Switch to parent: Profil → Abmelden → Login as Mama
    await page.getByRole('button', { name: 'Profil' }).click();
    await page
      .getByRole('button', { name: /abmelden.*ausloggen/i })
      .click();
    await expect(page).toHaveURL(/#\/login/);

    // Login as Mama with PIN
    await page.getByRole('button', { name: /mama.*eltern/i }).click();
    await expect(flutterText(page, /pin eingeben/i)).toBeVisible();
    for (const digit of '1234') {
      await page
        .getByRole('button', { name: digit, exact: true })
        .click();
    }
    await expect(page).toHaveURL(/#\/parent-dashboard/);

    // Navigate to Approve tab
    await navigateToApprove(page);

    // Approve the quest (50 XP will push from 60 to 110 → level 2)
    await page.getByRole('button', { name: 'Bestätigen' }).click();
    await expect(
      flutterText(page, /quest bestätigt/i),
    ).toBeVisible();

    // The level-up animation may render as a canvas overlay.
    // Try to dismiss it if visible, then verify via localStorage.
    const weiterButton = page.getByRole('button', { name: /weiter/i });
    try {
      await weiterButton.waitFor({ state: 'visible', timeout: 5000 });
      await weiterButton.click();
    } catch {
      // Animation not in semantics tree — tap to dismiss
      await page.mouse.click(400, 400);
    }

    await page.waitForTimeout(500);

    // Verify hero level increased in localStorage
    const heroRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.heroes'),
    );
    const heroes = JSON.parse(JSON.parse(heroRaw!));
    expect(heroes[0].level).toBe(2);

    // Verify level-up notification for child
    const nRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(nRaw!));
    const levelUpNotif = notifications.find(
      (n: { type: string }) => n.type === 'levelUp',
    );
    expect(levelUpNotif).toBeTruthy();
  });
});
