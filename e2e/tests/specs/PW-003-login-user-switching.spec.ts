/**
 * PW-003 — Login & Benutzerwechsel
 *
 * Source spec: docs/tests/playwright/PW-003-login-user-switching.md
 * IST-Analyse process: P3 (docs/IST_ANALYSE.md §3 / P3)
 * Tracking issue: #167
 *
 * Covers the LoginPage flow:
 *   - Tap an avatar without a PIN → directly logged in
 *   - Tap an avatar with a PIN → numeric keypad dialog opens
 *   - Correct PIN (auto-submits after 4 digits) → dashboard
 *   - Wrong PIN → "Falscher PIN" snackbar, user stays on login
 *   - Cancel button in dialog → no login, no snackbar
 *   - Logout from profile → back on login, re-login as a different
 *     role lands on the correct dashboard
 *
 * Empirical notes from exploring the live app (see FINDINGS.md):
 *   - The PIN dialog is NOT a text input. It's a custom numeric keypad:
 *     buttons "0".."9", an unlabeled backspace button, and "Abbrechen".
 *     Auto-submits after 4 digits — no explicit OK button.
 *   - "Wer bist du?" is a generic text node, not a heading → getByText.
 *   - Avatar buttons follow the pattern "<Initial> <Name> <Rolle>"
 *     (e.g. "M Mama Eltern", "L Luca Kind").
 *   - Logout button in the profile tab has the accessible name
 *     "Abmelden Aus dem Account ausloggen" — match with a regex.
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterText } from '../fixtures/flutter';
import { seedFamilyWithChild, IDS } from '../fixtures/seed';

/**
 * Types a PIN on the numeric keypad dialog.
 *
 * Auto-submits once `pin.length` digits are entered — do not assume
 * the dialog is still open after the last digit.
 */
async function enterPin(page: Page, pin: string): Promise<void> {
  for (const digit of pin) {
    await page.getByRole('button', { name: digit, exact: true }).click();
  }
}

test.describe('PW-003 Login & Benutzerwechsel', () => {
  // Shared starting point: family + members persisted, but nobody is
  // logged in, so the app routes to #/login.
  const loggedOutSeed = () => ({
    ...seedFamilyWithChild(),
    lastUserId: null,
  });

  test('TC-003.1 — child without a PIN logs in directly to hero home', async ({
    seededPage,
  }) => {
    const page = await seededPage(loggedOutSeed());

    await expect(page).toHaveURL(/#\/login/);
    await page.getByRole('button', { name: /luca.*kind/i }).click();

    // No PIN dialog — go straight to hero home
    await expect(page).toHaveURL(/#\/hero-home/);
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Storage reflects the new current user
    const lastUserId = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(lastUserId).toBe(JSON.stringify(IDS.childLucaId));
  });

  test('TC-003.2 — parent with a PIN logs in via the numeric keypad', async ({
    seededPage,
  }) => {
    const page = await seededPage(loggedOutSeed());

    await page.getByRole('button', { name: /mama.*eltern/i }).click();

    // Keypad dialog is open: see a textual label "PIN eingeben" plus the
    // digit buttons
    await expect(flutterText(page, /pin eingeben/i)).toBeVisible();
    await expect(
      page.getByRole('button', { name: '1', exact: true }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: 'Abbrechen' }),
    ).toBeVisible();

    // Typing "1234" auto-submits after the fourth digit
    await enterPin(page, '1234');

    await expect(page).toHaveURL(/#\/parent-dashboard/);
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    const lastUserId = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(lastUserId).toBe(JSON.stringify(IDS.parentMamaId));
  });

  test('TC-003.3 — wrong PIN keeps the user on the login page with an error', async ({
    seededPage,
  }) => {
    const page = await seededPage(loggedOutSeed());

    await page.getByRole('button', { name: /mama.*eltern/i }).click();
    await enterPin(page, '0000');

    // Dialog closes on auto-submit even when the PIN is wrong; the user
    // bounces back to the login grid with a snackbar
    await expect(page).toHaveURL(/#\/login/);
    await expect(flutterText(page, /falscher pin/i)).toBeVisible();

    // Still no current user persisted
    const lastUserId = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(lastUserId).toBeNull();
  });

  test('TC-003.4 — Abbrechen in the PIN dialog leaves no trace', async ({
    seededPage,
  }) => {
    const page = await seededPage(loggedOutSeed());

    await page.getByRole('button', { name: /mama.*eltern/i }).click();
    await expect(flutterText(page, /pin eingeben/i)).toBeVisible();

    await page.getByRole('button', { name: 'Abbrechen' }).click();

    // Back on the login grid, dialog is gone, no snackbar
    await expect(page).toHaveURL(/#\/login/);
    await expect(flutterText(page, /pin eingeben/i)).toHaveCount(0);
    await expect(flutterText(page, /falscher pin/i)).toHaveCount(0);
    await expect(
      page.getByRole('button', { name: /mama.*eltern/i }),
    ).toBeVisible();

    const lastUserId = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(lastUserId).toBeNull();
  });

  test('TC-003.5 — logout + re-login with a different role switches dashboards', async ({
    seededPage,
  }) => {
    // Start with Mama already logged in → parent dashboard
    const page = await seededPage(seedFamilyWithChild());
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    // Open profile tab → Abmelden
    await page.getByRole('button', { name: 'Profil' }).click();
    await page
      .getByRole('button', { name: /abmelden.*ausloggen/i })
      .click();

    await expect(page).toHaveURL(/#\/login/);

    // Re-login as Luca (no PIN)
    await page.getByRole('button', { name: /luca.*kind/i }).click();

    await expect(page).toHaveURL(/#\/hero-home/);
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    const lastUserId = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(lastUserId).toBe(JSON.stringify(IDS.childLucaId));
  });
});
