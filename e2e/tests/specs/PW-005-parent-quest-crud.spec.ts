/**
 * PW-005 — Parent: Quest CRUD
 *
 * Source spec: docs/tests/playwright/PW-005-parent-quest-crud.md
 * IST-Analyse process: P5
 * Tracking issue: #169
 *
 * Covers quest management from the parent dashboard:
 *   - Create a daily quest (happy path)
 *   - Create an epic quest with deadline
 *   - Create a series quest with unit field
 *   - Edit an existing quest
 *   - Delete a quest via swipe + confirmation
 *   - Validation: empty name / points
 *
 * Spec adjustments (documented in FINDINGS.md):
 *   - TC-005.2: Spec says "Typ Weekly, Rarity Epic, Deadline" but deadline
 *     only appears for type Epic → use type=Epic instead.
 *   - TC-005.3: Spec expects targetCount field, but it's not in the UI.
 *     Tested with unit field only.
 *   - TC-005.5 (deactivate): Skipped — no UI toggle exists for quest
 *     isActive, unlike rewards (see IST-Analyse §5.4).
 *
 * Semantics findings from live exploration:
 *   - ChoiceChips render as role="checkbox", not "button"
 *   - Quest card in list: button with combined name
 *     "Zimmer aufräumen Gewöhnlich Daily 10 Punkte • 100 XP"
 *   - Save button (Icons.check) in AppBar is unlabeled
 *   - FAB (Icons.add) is unlabeled
 *   - Edit heading: "Quest bearbeiten"
 *   - Filter: button "Show menu"
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterFill, flutterText, clickUnlabeledButton } from '../fixtures/flutter';
import { seedFamilyWithChild, seedFamilyWithQuestAndReward, IDS } from '../fixtures/seed';

/** Navigate to the Quests tab on the parent dashboard. */
async function navigateToQuests(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Quests' }).click();
  await expect(
    page.getByRole('heading', { name: /quest verwaltung/i }),
  ).toBeVisible();
}

/**
 * Click the save button (unlabeled Icons.check) in the QuestEditPage AppBar.
 *
 * The AppBar renders: Back button (labeled), heading, then the save button
 * (unlabeled). Both `heading.locator('..')` and `clickUnlabeledButton(body)`
 * are unreliable:
 *   - `.locator('..')` doesn't always resolve to the correct DOM parent
 *     in Flutter's flt-semantics tree.
 *   - body-level iteration can pick up icon picker buttons that sometimes
 *     appear before the save button in DOM order.
 *
 * Reliable approach: find the heading flt-semantics element, then get the
 * next sibling with role="button" — that's always the save button.
 */
async function clickSaveButton(page: Page): Promise<void> {
  await expect(
    page.getByRole('heading', { name: /quest/i }),
  ).toBeVisible();
  // The heading renders as <h2> inside a <flt-semantics> parent.
  // The save button is the <flt-semantics role="button"> immediately
  // following the <h2>. CSS adjacent sibling selector targets it precisely.
  // Using Playwright's native .click() (not dispatchEvent) so the event
  // goes through Flutter's event pipeline correctly.
  await page.locator('h2 + flt-semantics[role="button"]').click();
}

test.describe('PW-005 Parent: Quest CRUD', () => {
  test('TC-005.1 — Neue Daily-Quest anlegen (Happy Path)', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToQuests(page);

    // Empty state visible
    await expect(page.getByText('Keine Quests verfügbar')).toBeVisible();

    // Click "Quest erstellen" in empty state
    await page.getByRole('button', { name: 'Quest erstellen' }).click();
    await expect(
      page.getByRole('heading', { name: /quest erstellen/i }),
    ).toBeVisible();

    // Fill name
    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Zimmer aufräumen');

    // Type defaults to Daily (checked), Rarity to Gewöhnlich (checked)
    await expect(
      page.getByRole('checkbox', { name: 'Daily' }),
    ).toBeChecked();
    await expect(
      page.getByRole('checkbox', { name: 'Gewöhnlich' }),
    ).toBeChecked();

    // Points defaults to 10 in the controller, but Flutter's hidden
    // <input> doesn't reflect the controller value (see F-2).
    // We just accept the default and verify via localStorage after save.

    // "Alle Kinder" is checked by default (includes Luca)
    await expect(
      page.getByRole('checkbox', { name: 'Alle Kinder' }),
    ).toBeChecked();

    // Save
    await clickSaveButton(page);

    // Back on quest list, quest is visible
    await expect(
      page.getByRole('heading', { name: /quest verwaltung/i }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toBeVisible();

    // Verify localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    expect(raw).not.toBeNull();
    const quests = JSON.parse(JSON.parse(raw!));
    const quest = quests.find(
      (q: { name: string }) => q.name === 'Zimmer aufräumen',
    );
    expect(quest).toBeTruthy();
    expect(quest.type).toBe('daily');
    expect(quest.rewardPoints).toBe(10);
  });

  test('TC-005.2 — Epic-Quest mit Deadline', async ({ seededPage }) => {
    // Spec says "Typ Weekly, Rarity Epic, Deadline" but deadline only
    // appears for type=Epic. Adjusted to type=Epic, rarity=Epic.
    const page = await seededPage(seedFamilyWithChild());
    await navigateToQuests(page);

    await page.getByRole('button', { name: 'Quest erstellen' }).click();

    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Boss besiegen');

    // Select type Epic
    await page.getByRole('checkbox', { name: 'Epic' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Epic' }),
    ).toBeChecked();

    // Select rarity Episch
    await page.getByRole('checkbox', { name: 'Episch' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Episch' }),
    ).toBeChecked();

    // Deadline button is now visible
    await expect(
      page.getByRole('button', { name: /deadline/i }),
    ).toBeVisible();

    // Save without setting a specific deadline date (date picker is
    // hard to automate in Flutter Web, so we verify the field exists)
    await clickSaveButton(page);

    // Quest appears in list with Epic rarity
    await expect(
      page.getByRole('button', { name: /boss besiegen.*episch.*epic/i }),
    ).toBeVisible();

    // Verify in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    const quests = JSON.parse(JSON.parse(raw!));
    const quest = quests.find(
      (q: { name: string }) => q.name === 'Boss besiegen',
    );
    expect(quest).toBeTruthy();
    expect(quest.type).toBe('epic');
    expect(quest.rarity).toBe('epic');
  });

  test('TC-005.3 — Series-Quest mit Einheit', async ({ seededPage }) => {
    // Spec expects targetCount in UI, but it's not implemented.
    // Testing the unit field which IS available for Series quests.
    const page = await seededPage(seedFamilyWithChild());
    await navigateToQuests(page);

    await page.getByRole('button', { name: 'Quest erstellen' }).click();

    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Laufen');

    // Select type Series
    await page.getByRole('checkbox', { name: 'Series' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Series' }),
    ).toBeChecked();

    // Unit field appears for Series type
    const unitField = page.getByRole('textbox', {
      name: /einheit/i,
    });
    await expect(unitField).toBeVisible();
    await flutterFill(unitField, 'km');

    await clickSaveButton(page);

    // Quest appears in list
    await expect(
      page.getByRole('button', { name: /laufen/i }),
    ).toBeVisible();

    // Verify in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    const quests = JSON.parse(JSON.parse(raw!));
    const quest = quests.find(
      (q: { name: string }) => q.name === 'Laufen',
    );
    expect(quest).toBeTruthy();
    expect(quest.type).toBe('series');
    expect(quest.unit).toBe('km');
  });

  test('TC-005.4 — Quest bearbeiten', async ({ seededPage }) => {
    // Start with a seeded quest
    const page = await seededPage(seedFamilyWithQuestAndReward());
    await navigateToQuests(page);

    // Quest "Zimmer aufräumen" should be visible with 10 points
    const questButton = page.getByRole('button', {
      name: /zimmer aufräumen/i,
    });
    await expect(questButton).toBeVisible();

    // Tap quest to edit
    await questButton.click();
    await expect(
      page.getByRole('heading', { name: /quest bearbeiten/i }),
    ).toBeVisible();

    // Change points from 10 to 20.
    // Use the F-36 Backspace-loop pattern (select-all is unreliable on
    // Flutter textboxes).
    const pointsField = page.getByRole('textbox', { name: 'Punkte' });
    await pointsField.click();
    await pointsField.evaluate(() => new Promise((r) => setTimeout(r, 150)));
    await page.keyboard.press('End');
    for (let i = 0; i < 6; i++) {
      await page.keyboard.press('Backspace');
    }
    await pointsField.pressSequentially('20', { delay: 30 });

    await clickSaveButton(page);

    // Back in list, quest shows updated points
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen.*20 punkte/i }),
    ).toBeVisible();

    // Verify in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    const quests = JSON.parse(JSON.parse(raw!));
    expect(quests[0].rewardPoints).toBe(20);
  });

  test.skip('TC-005.5 — Quest deaktivieren (not implemented)', async () => {
    // Quest model has isActive property, but there is no UI toggle
    // to deactivate a quest. The Reward edit page has a SwitchListTile
    // for "Aktiv", but QuestEditPage does not. Skipping until the
    // feature is implemented.
  });

  test('TC-005.6 — Quest löschen', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithQuestAndReward());
    await navigateToQuests(page);

    const questButton = page.getByRole('button', {
      name: /zimmer aufräumen/i,
    });
    await expect(questButton).toBeVisible();

    // Swipe left to trigger Dismissible delete.
    // Flutter Web Dismissible responds to pointer drag events.
    const box = await questButton.boundingBox();
    expect(box).not.toBeNull();

    // Drag from center-right to far left
    await page.mouse.move(box!.x + box!.width - 20, box!.y + box!.height / 2);
    await page.mouse.down();
    await page.mouse.move(box!.x - 100, box!.y + box!.height / 2, {
      steps: 10,
    });
    await page.mouse.up();

    // Confirmation dialog appears
    await expect(page.getByText(/quest löschen/i)).toBeVisible();
    await expect(page.getByText(/zimmer aufräumen.*wirklich löschen/i)).toBeVisible();

    // Confirm deletion
    await page.getByRole('button', { name: 'Löschen' }).click();

    // Quest is gone from the list — empty state returns
    await expect(page.getByText('Keine Quests verfügbar')).toBeVisible();

    // Verify localStorage is empty
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    if (raw) {
      const quests = JSON.parse(JSON.parse(raw));
      expect(quests).toHaveLength(0);
    }
  });

  test('TC-005.7 — Validierung: leerer Name', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    await navigateToQuests(page);

    await page.getByRole('button', { name: 'Quest erstellen' }).click();

    // Leave name empty, try to save
    await clickSaveButton(page);

    // Validation error appears
    await expect(
      flutterText(page, /bitte name eingeben/i),
    ).toBeVisible();

    // Still on the create page (not navigated back)
    await expect(
      page.getByRole('heading', { name: /quest erstellen/i }),
    ).toBeVisible();

    // No quest was persisted
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quests'),
    );
    // Either null or empty array
    if (raw) {
      const quests = JSON.parse(JSON.parse(raw));
      expect(quests).toHaveLength(0);
    }
  });
});
