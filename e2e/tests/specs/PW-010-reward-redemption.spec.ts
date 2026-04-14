/**
 * PW-010 — Reward-Einlösung (Child + Parent)
 *
 * Source spec: docs/tests/playwright/PW-010-reward-redemption.md
 * IST-Analyse process: P6 (Redemption)
 * Tracking issue: #174
 *
 * Covers the redemption lifecycle: child requests, parent confirms or
 * rejects (with automatic refund).
 *
 * Setup chain (required because B-3 / B-8 prevent direct seeding of
 * balance and rewards — see PW-009):
 *   1. Start as parent with a pending quest
 *   2. Approve the quest → child earns points
 *   3. Parent creates a reward via the UI
 *   4. Logout → login as child → child buys the reward
 *   5. Run the redemption scenario under test
 *
 * Semantics findings:
 *   - MyRewardsPage tabs: "Aktiv", "Eingelöst"
 *   - Child redeem button on card: "Einlösen"
 *   - Redeem dialog: title "Einlösen", message "Zeige dies einem Elternteil!",
 *     buttons "Abbrechen" / "Einlösen anfragen"
 *   - After request: card label changes to "Warte auf Bestätigung"
 *   - Parent navigation: Rewards-Tab → "Einlösungen warten" banner →
 *     RedemptionPage with tabs "Ausstehend" / "Verlauf"
 *   - Parent action buttons on redemption card: "Ablehnen", "Bestätigen"
 *   - Reject dialog: "Einlösung ablehnen?" with message about refund,
 *     buttons "Abbrechen" / "Ablehnen"
 *
 * Skipped per spec:
 *   - TC-010.5 (child cancels pending redemption) — blocked by issue #153
 *   - TC-010.6 (child notification on decision) — blocked by issue #152
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterFill, flutterText } from '../fixtures/flutter';
import {
  seedFamilyWithQuestAndReward,
  IDS,
  type SeedPayload,
} from '../fixtures/seed';

/** Seed with a pending quest + parent logged in. */
function seedWithPendingQuest(): SeedPayload {
  const base = seedFamilyWithQuestAndReward();
  const now = new Date().toISOString();
  return {
    ...base,
    lastUserId: IDS.parentMamaId,
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

/** Approve the pending quest to give the child points. */
async function approvePendingQuest(page: Page): Promise<void> {
  await page.getByRole('button', { name: /approve/i }).click();
  await expect(
    page.getByRole('heading', { name: /freigabe/i }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Bestätigen' }).click();
  await expect(flutterText(page, /quest bestätigt/i)).toBeVisible();
}

/** Create a reward via the parent UI. */
async function parentCreateReward(
  page: Page,
  name: string,
  price: string,
): Promise<void> {
  await page.getByRole('button', { name: 'Rewards', exact: true }).click();
  await expect(
    page.getByRole('heading', { name: /belohnungen verwalten/i }),
  ).toBeVisible();
  const emptyButton = page.getByRole('button', {
    name: 'Belohnung erstellen',
  });
  if ((await emptyButton.count()) > 0 && (await emptyButton.isVisible())) {
    await emptyButton.click();
  } else {
    await page.getByRole('button', { name: 'Neue Belohnung' }).click();
  }
  await expect(
    page.getByRole('heading', { name: /neue belohnung/i }),
  ).toBeVisible();
  await flutterFill(page.getByRole('textbox', { name: /name/i }), name);
  await flutterFill(page.getByRole('textbox', { name: /preis/i }), price);
  await page.getByRole('button', { name: 'Speichern' }).click();
  await expect(flutterText(page, /belohnung erstellt/i)).toBeVisible();
}

/** Logout as parent, login as child Luca (no PIN). */
async function switchToChild(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page
    .getByRole('button', { name: /abmelden.*ausloggen/i })
    .click();
  await expect(page).toHaveURL(/#\/login/);
  await page.getByRole('button', { name: /luca.*kind/i }).click();
  await expect(page).toHaveURL(/#\/hero-home/);
}

/** Logout as child, login as parent Mama (PIN 1234 in the seed). */
async function switchToParent(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page
    .getByRole('button', { name: /abmelden.*ausloggen/i })
    .click();
  await expect(page).toHaveURL(/#\/login/);
  await page.getByRole('button', { name: /mama.*eltern/i }).click();
  // PIN keypad dialog — enter 1234 (auto-submits after 4 digits)
  await expect(flutterText(page, /pin eingeben/i)).toBeVisible();
  for (const digit of '1234') {
    await page.getByRole('button', { name: digit, exact: true }).click();
  }
  await expect(page).toHaveURL(/#\/parent-dashboard/);
}

/** Navigate as child from hero-home to "My Rewards" tab. */
async function childOpenMyRewards(page: Page): Promise<void> {
  // "Rewards" bottom-nav tab (index 2 in child nav)
  await page.getByRole('button', { name: 'Rewards', exact: true }).click();
}

/** Navigate as parent to the RedemptionPage via the banner on
 *  RewardManagementPage. The banner only renders when pendingCount > 0.
 *
 *  Note: when there are pending redemptions, the Rewards nav-tab label
 *  becomes "<count> Rewards" (same pattern as F-30 for Approve), so we
 *  cannot use `exact: true`. Use a regex ending in "rewards" to match
 *  both "Rewards" and "1 Rewards" / "2 Rewards" / …
 */
async function parentOpenRedemptions(page: Page): Promise<void> {
  await page.getByRole('button', { name: /\brewards$/i }).click();
  await expect(
    page.getByRole('heading', { name: /belohnungen verwalten/i }),
  ).toBeVisible();
  // Tap the "Einlösungen warten" banner
  await page.getByText(/einlösungen warten/i).click();
  await expect(
    page.getByRole('heading', { name: 'Einlösungen' }),
  ).toBeVisible();
}

/** Full setup: parent approves quest + creates reward; child buys it.
 *  After this, the Page is on the child's hero-home with one purchased
 *  reward in My Rewards. */
async function setupPurchasedReward(
  page: Page,
  {
    rewardName,
    rewardPrice,
  }: { rewardName: string; rewardPrice: string },
): Promise<void> {
  // Seed must already be applied by the test; this helper assumes we're
  // on parent dashboard.
  await approvePendingQuest(page);
  await parentCreateReward(page, rewardName, rewardPrice);
  await switchToChild(page);

  // Child: open shop, buy the reward
  await page.getByRole('button', { name: 'Shop', exact: true }).last().click();
  await expect(
    page.getByRole('heading', { name: 'Shop' }),
  ).toBeVisible();
  // Reward card is a button "<name> ✨ <price> Kaufen"
  await page
    .getByRole('button', {
      name: new RegExp(`${rewardName.toLowerCase()}.*kaufen`, 'i'),
    })
    .click();
  await expect(
    page.getByText(/möchtest du diese belohnung kaufen/i),
  ).toBeVisible();
  // Dialog's exact-match "Kaufen" confirm button
  await page.getByRole('button', { name: 'Kaufen', exact: true }).click();
  await expect(flutterText(page, /gekauft/i)).toBeVisible();
}

test.describe('PW-010 Reward-Einlösung', () => {
  test('TC-010.1 — Kind fragt Einlösung an', async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    await setupPurchasedReward(page, {
      rewardName: 'Sticker',
      rewardPrice: '5',
    });

    await childOpenMyRewards(page);

    // Reward visible with "Einlösen" action
    await expect(
      page.getByRole('button', { name: 'Einlösen' }),
    ).toBeVisible();
    await page.getByRole('button', { name: 'Einlösen' }).click();

    // Dialog appears with "Einlösen anfragen" button
    await expect(
      page.getByText(/zeige dies einem elternteil/i),
    ).toBeVisible();
    await page
      .getByRole('button', { name: 'Einlösen anfragen' })
      .click();

    // Snackbar confirmation
    await expect(
      flutterText(page, /einlösung angefragt.*warte auf bestätigung/i),
    ).toBeVisible();

    // Verify purchase status in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.purchases'),
    );
    const purchases = JSON.parse(JSON.parse(raw!));
    expect(purchases[0].status).toBe('pendingRedemption');
  });

  test('TC-010.2 — Parent sieht pending Einlösung im Banner und RedemptionPage',
      async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    await setupPurchasedReward(page, {
      rewardName: 'Sticker',
      rewardPrice: '5',
    });

    // Child requests redemption
    await childOpenMyRewards(page);
    await page.getByRole('button', { name: 'Einlösen' }).click();
    await page
      .getByRole('button', { name: 'Einlösen anfragen' })
      .click();
    await expect(
      flutterText(page, /einlösung angefragt/i),
    ).toBeVisible();

    // Switch back to parent and navigate to redemption page
    await switchToParent(page);
    await parentOpenRedemptions(page);

    // Pending redemption card shows the reward + child name
    await expect(
      page.getByRole('group', { name: /sticker/i }),
    ).toBeVisible();

    // Approve/Reject buttons visible
    await expect(
      page.getByRole('button', { name: 'Bestätigen' }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Ablehnen' }),
    ).toBeVisible();
  });

  test('TC-010.3 — Parent bestätigt Einlösung', async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    await setupPurchasedReward(page, {
      rewardName: 'Sticker',
      rewardPrice: '5',
    });

    // Child request
    await childOpenMyRewards(page);
    await page.getByRole('button', { name: 'Einlösen' }).click();
    await page
      .getByRole('button', { name: 'Einlösen anfragen' })
      .click();
    await expect(
      flutterText(page, /einlösung angefragt/i),
    ).toBeVisible();

    // Parent confirms
    await switchToParent(page);
    await parentOpenRedemptions(page);
    await page.getByRole('button', { name: 'Bestätigen' }).click();

    // Snackbar
    await expect(
      flutterText(page, /einlösung bestätigt/i),
    ).toBeVisible();

    // Verify purchase status + metadata in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.purchases'),
    );
    const purchases = JSON.parse(JSON.parse(raw!));
    expect(purchases[0].status).toBe('redeemed');
    expect(purchases[0].redeemedAt).not.toBeNull();
    expect(purchases[0].redeemedBy).toBe(IDS.parentMamaId);
  });

  test('TC-010.4 — Parent lehnt Einlösung ab, Punkte werden refundiert',
      async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    await setupPurchasedReward(page, {
      rewardName: 'Sticker',
      rewardPrice: '5',
    });

    // Balance after buy: 10 earned - 5 spent = 5
    const balanceBeforeRefund = await page.evaluate(() => {
      const raw = window.localStorage.getItem('flutter.points_accounts');
      if (!raw) return null;
      const accs = JSON.parse(JSON.parse(raw));
      return accs[0]?.balance ?? null;
    });
    expect(balanceBeforeRefund).toBe(5);

    // Child requests redemption
    await childOpenMyRewards(page);
    await page.getByRole('button', { name: 'Einlösen' }).click();
    await page
      .getByRole('button', { name: 'Einlösen anfragen' })
      .click();
    await expect(
      flutterText(page, /einlösung angefragt/i),
    ).toBeVisible();

    // Parent rejects
    await switchToParent(page);
    await parentOpenRedemptions(page);
    await page.getByRole('button', { name: 'Ablehnen' }).click();

    // Rejection confirmation dialog appears with refund warning
    await expect(
      page.getByText(/punkte werden dem kind zurückerstattet/i),
    ).toBeVisible();
    // Two "Ablehnen" buttons now exist (card + dialog). The dialog's is last.
    await page.getByRole('button', { name: 'Ablehnen' }).last().click();

    // Snackbar
    await expect(
      flutterText(page, /einlösung abgelehnt.*zurückerstattet/i),
    ).toBeVisible();

    // Verify status is cancelled
    const purchaseRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.purchases'),
    );
    const purchases = JSON.parse(JSON.parse(purchaseRaw!));
    expect(purchases[0].status).toBe('cancelled');

    // Verify balance was refunded (5 + 5 refund = 10)
    const balanceAfterRefund = await page.evaluate(() => {
      const raw = window.localStorage.getItem('flutter.points_accounts');
      const accs = JSON.parse(JSON.parse(raw!));
      return accs[0]?.balance ?? null;
    });
    expect(balanceAfterRefund).toBe(10);

    // Verify refund transaction
    const txnRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.transactions'),
    );
    const txns = JSON.parse(JSON.parse(txnRaw!));
    const refundTxn = txns.find(
      (t: { type: string }) => t.type === 'refund',
    );
    expect(refundTxn).toBeTruthy();
    expect(refundTxn.amount).toBe(5);
  });

  test.skip('TC-010.5 — Kind bricht pending Einlösung ab (blocked by #153)',
      () => {
    // No UI exists for the child to cancel a pending redemption.
    // See docs/tests/playwright/PW-010-reward-redemption.md TC-010.5.
  });

  test('TC-010.6 — Kind erhält Notification bei Einlösungs-Entscheidung',
      async ({ seededPage }) => {
    // Closes issue #152: both confirmRedemption and rejectRedemption
    // now create a child-facing notification. We verify the confirm
    // path here; the reject-path notification is structurally identical
    // and could be exercised by extending TC-010.4 — but keeping this
    // test focused makes debugging simpler if the feature regresses.
    const page = await seededPage(seedWithPendingQuest());

    await setupPurchasedReward(page, {
      rewardName: 'Sticker',
      rewardPrice: '5',
    });

    // Child requests redemption
    await childOpenMyRewards(page);
    await page.getByRole('button', { name: 'Einlösen' }).click();
    await page
      .getByRole('button', { name: 'Einlösen anfragen' })
      .click();
    await expect(
      flutterText(page, /einlösung angefragt/i),
    ).toBeVisible();

    // Parent confirms
    await switchToParent(page);
    await parentOpenRedemptions(page);
    await page.getByRole('button', { name: 'Bestätigen' }).click();
    await expect(flutterText(page, /einlösung bestätigt/i)).toBeVisible();

    // Child-facing notification created
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(raw!));
    const childNotif = notifications.find(
      (n: { type: string; userId: string }) =>
        n.type === 'rewardConfirmed' && n.userId === IDS.childLucaId,
    );
    expect(childNotif).toBeTruthy();
    expect(childNotif.title).toContain('bestätigt');
    expect(childNotif.message).toContain('Sticker');
  });
});
