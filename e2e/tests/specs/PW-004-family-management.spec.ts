/**
 * PW-004 — Familienmitglied hinzufügen
 *
 * Source spec: docs/tests/playwright/PW-004-family-management.md
 * IST-Analyse process: P4 (docs/IST_ANALYSE.md §3 / P4)
 * Tracking issue: #168
 *
 * Covers the family management flow from the parent profile tab:
 *   - View existing members on the family management page
 *   - Add a child member (no PIN)
 *   - Add a second parent with a PIN, then verify login
 *   - Cancel the add-member dialog without persisting
 *
 * Navigation path:
 *   Parent Dashboard → Profil tab → "Familie verwalten" → FamilyManagementPage
 *
 * The add-member flow uses an AlertDialog (not a separate page):
 *   - Title: "Mitglied hinzufügen"
 *   - Fields: Name (textbox), Rolle (dropdown, default "Kind"), PIN (optional)
 *   - Buttons: "Abbrechen", "Hinzufügen"
 *
 * The FAB has tooltip "Mitglied hinzufügen" (#206 fix), matched by
 * role=button.
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterFill, flutterText } from '../fixtures/flutter';
import { seedFamilyWithParent, seedFamilyWithChild, IDS } from '../fixtures/seed';

/** Navigate from parent dashboard to the family management page. */
async function navigateToFamilyManagement(page: Page): Promise<void> {
  // Open the profile tab
  await page.getByRole('button', { name: 'Profil' }).click();
  // Click "Familie verwalten" settings item
  await page.getByRole('button', { name: /familie verwalten/i }).click();
  // Wait for the family management page to be visible
  await expect(page.getByText(/familie test-familie/i)).toBeVisible();
}

/** Open the add-member dialog via the FAB. */
async function openAddMemberDialog(page: Page): Promise<void> {
  // FAB has tooltip "Mitglied hinzufügen" (#206). The dialog title is
  // the same text (rendered as plain text, not a button), so disambiguate
  // by role when clicking vs asserting visibility.
  await page
    .getByRole('button', { name: 'Mitglied hinzufügen' })
    .click();
  await expect(page.getByText('Mitglied hinzufügen')).toBeVisible();
}

/**
 * Types a PIN on the numeric keypad dialog.
 * Reused from PW-003 — auto-submits after pin.length digits.
 */
async function enterPin(page: Page, pin: string): Promise<void> {
  for (const digit of pin) {
    await page.getByRole('button', { name: digit, exact: true }).click();
  }
}

test.describe('PW-004 Familienmitglied hinzufügen', () => {
  test('TC-004.1 — Liste vorhandener Mitglieder', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithParent());

    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    await navigateToFamilyManagement(page);

    // Mama appears under the "Eltern" section
    await expect(page.getByText('Mama')).toBeVisible();
    await expect(page.getByText('Elternteil')).toBeVisible();

    // No children yet
    await expect(
      page.getByText('Noch keine Kinder hinzugefügt'),
    ).toBeVisible();

    // Member count
    await expect(page.getByText('1 Familienmitglieder')).toBeVisible();
  });

  test('TC-004.2 — Kind hinzufügen', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithParent());
    await navigateToFamilyManagement(page);

    await openAddMemberDialog(page);

    // Fill in the name — the dialog has a textbox labeled "Name"
    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Luca');

    // Role defaults to "Kind" — no change needed

    // Click "Hinzufügen"
    await page.getByRole('button', { name: 'Hinzufügen' }).click();

    // Dialog closes, Luca appears in the member list
    await expect(page.getByText('Luca')).toBeVisible();
    await expect(page.getByText('Mochi Hero')).toBeVisible();

    // "Noch keine Kinder" hint is gone
    await expect(
      page.getByText('Noch keine Kinder hinzugefügt'),
    ).toHaveCount(0);

    // Member count updated
    await expect(page.getByText('2 Familienmitglieder')).toBeVisible();

    // Verify localStorage contains the new child
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.family_members'),
    );
    expect(raw).not.toBeNull();
    const members = JSON.parse(JSON.parse(raw!));
    const luca = members.find((m: { name: string }) => m.name === 'Luca');
    expect(luca).toBeTruthy();
    expect(luca.role).toBe('child');
  });

  test('TC-004.3 — Zweiten Parent hinzufügen mit PIN', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithParent());
    await navigateToFamilyManagement(page);

    await openAddMemberDialog(page);

    // Fill in name
    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Papa');

    // Change role to "Elternteil" — click the dropdown, then select.
    // Flutter renders DropdownButtonFormField items as role="menuitem"
    // inside a role="menu" popup (not role="option").
    await page.getByRole('button', { name: /kind/i }).click();
    await page.getByRole('menuitem', { name: 'Elternteil' }).click();

    // Fill in PIN
    const pinField = page.getByRole('textbox', { name: /pin/i });
    await flutterFill(pinField, '5555');

    // Submit
    await page.getByRole('button', { name: 'Hinzufügen' }).click();

    // Papa appears in the member list as "Elternteil"
    await expect(page.getByText('Papa')).toBeVisible();

    // Count: Mama + Papa = 2
    await expect(page.getByText('2 Familienmitglieder')).toBeVisible();

    // Now verify Papa can log in with PIN 5555:
    // Navigate back to dashboard, then logout
    await page.getByRole('button', { name: /zurück/i }).click();
    await page
      .getByRole('button', { name: /abmelden.*ausloggen/i })
      .click();

    await expect(page).toHaveURL(/#\/login/);

    // Login as Papa with PIN
    await page.getByRole('button', { name: /papa.*eltern/i }).click();
    await expect(flutterText(page, /pin eingeben/i)).toBeVisible();
    await enterPin(page, '5555');

    await expect(page).toHaveURL(/#\/parent-dashboard/);
    await expect(
      page.getByRole('heading', { name: /hallo,\s*papa/i }),
    ).toBeVisible();
  });

  test('TC-004.4 — Abbrechen beim Hinzufügen', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithParent());
    await navigateToFamilyManagement(page);

    // Remember current member count
    await expect(page.getByText('1 Familienmitglieder')).toBeVisible();

    await openAddMemberDialog(page);

    // Fill in some data
    const nameField = page.getByRole('textbox', { name: 'Name' });
    await flutterFill(nameField, 'Ghost');

    // Cancel
    await page.getByRole('button', { name: 'Abbrechen' }).click();

    // Dialog closes — check via a dialog-only element (the Name textbox)
    // since the dialog's "Mitglied hinzufügen" title collides with the
    // FAB's tooltip (#206) in the accessible tree.
    await expect(
      page.getByRole('textbox', { name: 'Name' }),
    ).toHaveCount(0);

    // Member count unchanged
    await expect(page.getByText('1 Familienmitglieder')).toBeVisible();

    // "Ghost" does not appear
    await expect(page.getByText('Ghost')).toHaveCount(0);

    // Verify localStorage is unchanged
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.family_members'),
    );
    expect(raw).not.toBeNull();
    const members = JSON.parse(JSON.parse(raw!));
    expect(members).toHaveLength(1);
    expect(members[0].name).toBe('Mama');
  });
});
