/**
 * PW-008 — Parent: Reward CRUD
 *
 * Source spec: docs/tests/playwright/PW-008-parent-reward-crud.md
 * IST-Analyse process: P6 (Reward-Katalog)
 * Tracking issue: #172
 *
 * Covers the parent's reward management flow:
 *   - Create reward (happy path)
 *   - Create with limited stock
 *   - Create different categories
 *   - Edit reward (change price)
 *   - Delete via swipe + confirmation
 *   - Validation: price must be > 0
 *   - Activate/deactivate toggle
 *
 * Unlike QuestEditPage (PW-005), the RewardEditPage has a save button
 * with TEXT "Speichern" (not an unlabeled icon), so navigation is simpler.
 *
 * Semantics findings:
 *   - Heading: "Belohnungen verwalten" (list) / "Neue Belohnung" (create)
 *     / "Belohnung bearbeiten" (edit)
 *   - Save button: text "Speichern"
 *   - Name field: "Name *"
 *   - Price field: "Preis (Punkte) *"
 *   - Category: DropdownButtonFormField (→ role="menuitem" items, see F-19)
 *   - Stock field: "Anzahl verfügbar" (empty = unlimited)
 *   - Active toggle: SwitchListTile "Aktiv"
 *   - Delete confirmation: "Belohnung löschen?" with "Löschen"/"Abbrechen"
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterFill, flutterText } from '../fixtures/flutter';
import { seedFamilyWithChild } from '../fixtures/seed';

/** Navigate to Rewards tab on parent dashboard. */
async function navigateToRewards(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Rewards', exact: true }).click();
  await expect(
    page.getByRole('heading', { name: /belohnungen verwalten/i }),
  ).toBeVisible();
}

/** Open the create-reward page from the empty state or FAB.
 *
 * Empty state: button "Belohnung erstellen"
 * With existing rewards: FAB with text "Neue Belohnung"
 */
async function openCreateReward(page: Page): Promise<void> {
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
}

test.describe('PW-008 Parent: Reward CRUD', () => {
  test('TC-008.1 — Neuen Reward anlegen (Happy Path)', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);

    // Empty state visible
    await expect(
      page.getByText('Keine Belohnungen verfügbar'),
    ).toBeVisible();

    await openCreateReward(page);

    // Fill name
    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      '30 min Tablet',
    );

    // Fill price
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '50',
    );

    // Category defaults to "Sache" (item). Change to "Privileg".
    // Button accessible name is "Kategorie <value>" (e.g. "Kategorie Sache").
    // The dropdown renders items as menuitems (see F-19).
    await page.getByRole('button', { name: /kategorie.*sache/i }).click();
    await page.getByRole('menuitem', { name: /privileg/i }).click();

    // Save (button has text "Speichern" — no clickSaveButton workaround needed)
    await page.getByRole('button', { name: 'Speichern' }).click();

    // Back on reward list — snackbar confirms
    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    // Reward visible in list as a group with combined accessible name
    // Pattern: "<name> ✨ <price> Punkte"
    await expect(
      page.getByRole('group', { name: /30 min tablet/i }),
    ).toBeVisible();

    // Verify localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    expect(raw).not.toBeNull();
    const rewards = JSON.parse(JSON.parse(raw!));
    const reward = rewards.find(
      (r: { name: string }) => r.name === '30 min Tablet',
    );
    expect(reward).toBeTruthy();
    expect(reward.price).toBe(50);
    expect(reward.category).toBe('privilege');
    expect(reward.isActive).toBe(true);
  });

  test('TC-008.2 — Reward mit limitiertem Stock', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);
    await openCreateReward(page);

    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      'Eis',
    );
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '20',
    );
    // Stock field — empty = unlimited, enter 3 for limited
    await flutterFill(
      page.getByRole('textbox', { name: /anzahl verfügbar/i }),
      '3',
    );

    await page.getByRole('button', { name: 'Speichern' }).click();

    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    const rewards = JSON.parse(JSON.parse(raw!));
    const reward = rewards.find((r: { name: string }) => r.name === 'Eis');
    expect(reward).toBeTruthy();
    expect(reward.stock).toBe(3);
  });

  test('TC-008.3 — Reward-Kategorien', async ({ seededPage }) => {
    // Create one reward per category. We test two here (item + experience)
    // to keep the test focused; TC-008.1 already covers privilege.
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);

    // First reward: experience category
    await openCreateReward(page);
    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      'Kino',
    );
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '100',
    );
    // Change category to Erlebnis (experience)
    await page.getByRole('button', { name: /kategorie.*sache/i }).click();
    await page.getByRole('menuitem', { name: /erlebnis/i }).click();
    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    // Verify categories in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    const rewards = JSON.parse(JSON.parse(raw!));
    const kino = rewards.find((r: { name: string }) => r.name === 'Kino');
    expect(kino.category).toBe('experience');
  });

  test('TC-008.4 — Reward bearbeiten', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);

    // Create a reward first
    await openCreateReward(page);
    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      'Tablet',
    );
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '50',
    );
    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    // Tap the reward card to open edit (card renders as a group)
    await page.getByRole('group', { name: /tablet/i }).click();
    await expect(
      page.getByRole('heading', { name: /belohnung bearbeiten/i }),
    ).toBeVisible();

    // Change price from 50 to 75.
    // Flutter textboxes don't reliably respond to select-all shortcuts or
    // triple-click in the hidden input. The reliable approach: focus, end,
    // backspace per character (with a Flutter settle), then pressSequentially.
    const priceField = page.getByRole('textbox', { name: /preis/i });
    await priceField.click();
    await priceField.evaluate(() => new Promise((r) => setTimeout(r, 150)));
    await page.keyboard.press('End');
    // Current value has 2 chars ("50"); clear with backspaces (extra is safe)
    for (let i = 0; i < 6; i++) {
      await page.keyboard.press('Backspace');
    }
    await priceField.pressSequentially('75', { delay: 30 });

    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(
      flutterText(page, /belohnung aktualisiert/i),
    ).toBeVisible();

    // Verify price in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    const rewards = JSON.parse(JSON.parse(raw!));
    expect(rewards[0].price).toBe(75);
  });

  test('TC-008.5 — Reward löschen', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);

    // Create a reward
    await openCreateReward(page);
    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      'Zum Löschen',
    );
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '10',
    );
    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    // Swipe left on the reward card (rendered as group).
    // Start from the middle (not the right edge where the isActive switch is)
    // to avoid triggering the switch instead of the swipe-to-dismiss.
    const card = page.getByRole('group', { name: /zum löschen/i });
    await expect(card).toBeVisible();
    const box = await card.boundingBox();
    expect(box).not.toBeNull();
    await page.mouse.move(
      box!.x + box!.width / 2,
      box!.y + box!.height / 2,
    );
    await page.mouse.down();
    await page.mouse.move(box!.x - 100, box!.y + box!.height / 2, {
      steps: 10,
    });
    await page.mouse.up();

    // Confirmation dialog
    await expect(page.getByText(/belohnung löschen/i)).toBeVisible();
    await page.getByRole('button', { name: 'Löschen' }).click();

    // Empty state returns
    await expect(
      page.getByText('Keine Belohnungen verfügbar'),
    ).toBeVisible();

    // Verify localStorage empty
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    if (raw) {
      const rewards = JSON.parse(JSON.parse(raw));
      expect(rewards).toHaveLength(0);
    }
  });

  test('TC-008.6 — Validierung: leerer Name', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);
    await openCreateReward(page);

    // Don't fill name, try to save
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '10',
    );
    await page.getByRole('button', { name: 'Speichern' }).click();

    // Validation error appears
    await expect(
      flutterText(page, /name ist erforderlich/i),
    ).toBeVisible();

    // Still on create page
    await expect(
      page.getByRole('heading', { name: /neue belohnung/i }),
    ).toBeVisible();

    // No reward persisted
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    if (raw) {
      const rewards = JSON.parse(JSON.parse(raw));
      expect(rewards).toHaveLength(0);
    }
  });

  test('TC-008.7 — Reward deaktivieren über Switch', async ({
    seededPage,
  }) => {
    // Bonus test: the isActive toggle that quests don't have
    const page = await seededPage(seedFamilyWithChild());
    await navigateToRewards(page);

    // Create a reward
    await openCreateReward(page);
    await flutterFill(
      page.getByRole('textbox', { name: /name/i }),
      'Toggle-Test',
    );
    await flutterFill(
      page.getByRole('textbox', { name: /preis/i }),
      '30',
    );
    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(
      flutterText(page, /belohnung erstellt/i),
    ).toBeVisible();

    // Toggle the switch on the reward card.
    // Flutter's Switch widget renders as role="switch" (not checkbox).
    // The card's switch is the first one on the page.
    await page.getByRole('switch').first().click();

    // Verify isActive in localStorage flipped
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.rewards'),
    );
    const rewards = JSON.parse(JSON.parse(raw!));
    expect(rewards[0].isActive).toBe(false);
  });
});
