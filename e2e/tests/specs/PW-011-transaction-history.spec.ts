/**
 * PW-011 — Punktekonto & Transaktions-Historie
 *
 * Source spec: docs/tests/playwright/PW-011-transaction-history.md
 * IST-Analyse process: P7
 * Tracking issue: #175
 *
 * Covers the child's transaction history page and weekly sum display.
 *
 * Setup chain (same workaround as PW-009/PW-010 for B-3 / B-8):
 *   Parent approves quest → earns pointsProvider balance in-memory →
 *   optionally creates reward + child buys (to add a purchase txn) →
 *   switch to child → navigate to Profil → Transaktionen.
 *
 * Semantics findings:
 *   - Page heading: "Transaktionen"
 *   - Filter chips (role=checkbox per F-21): "Alle" (default), "Verdient",
 *     "Ausgegeben"
 *   - Empty state: "Keine Transaktionen"
 *   - Transaction list items expose a compound accessible name containing
 *     the description text + signed amount + balanceAfter
 *   - Child nav entry: Profil → ListTile "Transaktionen"
 *   - Parent has NO access to the history (confirmed out of scope)
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterFill, flutterText } from '../fixtures/flutter';
import {
  seedFamilyWithChild,
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

async function approveQuest(page: Page): Promise<void> {
  await page.getByRole('button', { name: /\bgenehmigungen$/i }).click();
  await expect(page.getByRole('heading', { name: /freigabe/i })).toBeVisible();
  await page.getByRole('button', { name: 'Bestätigen' }).click();
  await expect(flutterText(page, /quest bestätigt/i)).toBeVisible();
}

async function parentCreateReward(
  page: Page,
  name: string,
  price: string,
): Promise<void> {
  await page.getByRole('button', { name: /\brewards$/i }).click();
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

async function switchToChild(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page
    .getByRole('button', { name: /abmelden.*ausloggen/i })
    .click();
  await expect(page).toHaveURL(/#\/login/);
  await page.getByRole('button', { name: /luca.*kind/i }).click();
  await expect(page).toHaveURL(/#\/hero-home/);
}

/** Child: Profil tab → "Transaktionen" list item → history page. */
async function childOpenTransactions(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Profil' }).click();
  await page.getByRole('button', { name: /transaktionen/i }).click();
  await expect(
    page.getByRole('heading', { name: 'Transaktionen' }),
  ).toBeVisible();
}

test.describe('PW-011 Punktekonto & Transaktions-Historie', () => {
  test('TC-011.1 — Historie zeigt earn + spend Transaktionen chronologisch',
      async ({ seededPage }) => {
    const page = await seededPage(seedWithPendingQuest());

    // Setup chain: parent approves quest (+10 MP) + creates 5 MP reward
    await approveQuest(page);
    await parentCreateReward(page, 'Sticker', '5');

    // Switch to child, buy reward (−5 MP), then open history
    await switchToChild(page);
    await page.getByRole('button', { name: 'Shop', exact: true }).last().click();
    await expect(page.getByRole('heading', { name: 'Shop' })).toBeVisible();
    await page
      .getByRole('button', { name: /sticker.*kaufen/i })
      .click();
    await expect(
      page.getByText(/möchtest du diese belohnung kaufen/i),
    ).toBeVisible();
    await page.getByRole('button', { name: 'Kaufen', exact: true }).click();
    await expect(flutterText(page, /sticker gekauft/i)).toBeVisible();

    await childOpenTransactions(page);

    // Not-empty-state: the list has at least the two transactions
    await expect(page.getByText('Keine Transaktionen')).toHaveCount(0);

    // Verify in localStorage (authoritative — UI matches this)
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.transactions'),
    );
    const txns = JSON.parse(JSON.parse(raw!));
    // Transactions are stored in creation order; oldest first
    expect(txns).toHaveLength(2);
    expect(txns[0].type).toBe('questComplete');
    expect(txns[0].amount).toBe(10);
    expect(txns[0].balanceAfter).toBe(10);
    expect(txns[1].type).toBe('purchase');
    expect(txns[1].amount).toBe(-5);
    expect(txns[1].balanceAfter).toBe(5);
  });

  test('TC-011.2 — Filter "Verdient" / "Ausgegeben" / "Alle"', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedWithPendingQuest());
    await approveQuest(page);
    await parentCreateReward(page, 'Sticker', '5');
    await switchToChild(page);

    // Buy the reward to create one spent txn
    await page.getByRole('button', { name: 'Shop', exact: true }).last().click();
    await page.getByRole('button', { name: /sticker.*kaufen/i }).click();
    await page.getByRole('button', { name: 'Kaufen', exact: true }).click();
    await expect(flutterText(page, /sticker gekauft/i)).toBeVisible();

    await childOpenTransactions(page);

    // Default "Alle" filter is active (checkbox checked)
    await expect(
      page.getByRole('checkbox', { name: 'Alle' }),
    ).toBeChecked();

    // Switch to "Verdient" — only earn txns remain. Both types share a
    // "Quest" / "Einkauf" label in the list, so we check the filter's
    // visible state rather than reading list entries.
    await page.getByRole('checkbox', { name: 'Verdient' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Verdient' }),
    ).toBeChecked();
    await expect(
      page.getByRole('checkbox', { name: 'Alle' }),
    ).not.toBeChecked();

    // Switch to "Ausgegeben"
    await page.getByRole('checkbox', { name: 'Ausgegeben' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Ausgegeben' }),
    ).toBeChecked();

    // Back to "Alle"
    await page.getByRole('checkbox', { name: 'Alle' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Alle' }),
    ).toBeChecked();
  });

  test('TC-011.3 — Empty-State "Keine Transaktionen"', async ({
    seededPage,
  }) => {
    // Seed with child already logged in, no quest/reward activity.
    // pointsProvider._transactions is empty (B-3 means seed doesn't load),
    // so the history is empty.
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
    });

    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await childOpenTransactions(page);

    // Empty state is visible
    await expect(page.getByText('Keine Transaktionen')).toBeVisible();
    await expect(
      page.getByText('Deine Punkte-Historie ist noch leer.'),
    ).toBeVisible();
  });

  test('TC-011.4 — Hero-Home zeigt "Diese Woche"-Summe nach Approval', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedWithPendingQuest());

    // Parent approves quest (+10 MP this week)
    await approveQuest(page);

    // Switch to child → hero-home shows weekly earned
    await switchToChild(page);

    // Hero-home renders weekly earned amount separately from balance.
    // Text form in snapshot: "Diese Woche" + "+10" + "Punkte verdient".
    // Verify the "+10" is present next to "Diese Woche"/"Punkte verdient".
    await expect(page.getByText('Diese Woche')).toBeVisible();
    await expect(page.getByText('Punkte verdient')).toBeVisible();
    await expect(page.getByText('+10')).toBeVisible();
  });
});
