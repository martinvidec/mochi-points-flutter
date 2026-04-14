/**
 * PW-016 — Bottom-Navigation & Logout
 *
 * Source spec: docs/tests/playwright/PW-016-navigation-logout.md
 * IST-Analyse process: cross-cutting (P3, P5, P6, P8, P10)
 * Tracking issue: #180
 *
 * Covers the bottom navigation in both Parent and Child dashboards,
 * logout, and post-refresh auth persistence.
 *
 * Parent tabs: Home, Quests, Rewards, Approve, Profil
 * Child tabs:  Home, Quests, Rewards, Shop, Profil
 *
 * Child's "Rewards" tab shows the MyRewardsPage (heading
 * "Meine Belohnungen") — distinct from the parent's
 * RewardManagementPage (heading "Belohnungen verwalten").
 *
 * Parts of this spec overlap with earlier ones:
 *   - Tab navigation is implicitly exercised by PW-005/PW-006/PW-008/…
 *   - Logout round-trip is in PW-003 TC-003.5
 * Here we add focused cross-cutting assertions (all 5 tabs of each
 * role, IndexedStack state preservation, refresh-survives-auth) that
 * no single earlier spec owns.
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { seedFamilyWithChild, IDS } from '../fixtures/seed';

/** Click a bottom-nav tab using a regex that tolerates badge-prefixed
 *  labels ("1 Approve", "N Rewards") and the secondary "Shop"/"Alle
 *  Quests" buttons on the child home tab. */
async function clickTab(page: Page, tab: string): Promise<void> {
  await page
    .getByRole('button', { name: new RegExp(`\\b${tab}$`, 'i') })
    .last()
    .click();
}

test.describe('PW-016 Bottom-Navigation & Logout', () => {
  test('TC-016.1 — Parent: alle 5 Tabs wechseln', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());

    // Starts on Home tab by default
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    await clickTab(page, 'Quests');
    await expect(
      page.getByRole('heading', { name: /quest verwaltung/i }),
    ).toBeVisible();

    await clickTab(page, 'Rewards');
    await expect(
      page.getByRole('heading', { name: /belohnungen verwalten/i }),
    ).toBeVisible();

    await clickTab(page, 'Approve');
    await expect(
      page.getByRole('heading', { name: /freigabe/i }),
    ).toBeVisible();

    await clickTab(page, 'Profil');
    // Profile tab has Abmelden button but no dedicated heading — check that
    await expect(
      page.getByRole('button', { name: /abmelden.*ausloggen/i }),
    ).toBeVisible();

    // Back to Home tab
    await clickTab(page, 'Home');
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();
  });

  test('TC-016.2 — IndexedStack bewahrt Provider-State beim Tab-Wechsel',
      async ({ seededPage }) => {
    // IndexedStack keeps each tab's subtree mounted, so the in-memory
    // provider state that a tab has populated survives a tab switch.
    // Prove this: create a reward on the Rewards tab, switch to Home,
    // switch back, confirm the reward is still listed (not re-loaded
    // from an empty storage snapshot).
    const page = await seededPage(seedFamilyWithChild());

    await clickTab(page, 'Rewards');
    await expect(
      page.getByRole('heading', { name: /belohnungen verwalten/i }),
    ).toBeVisible();

    // Create a reward via the empty-state button
    await page.getByRole('button', { name: 'Belohnung erstellen' }).click();
    await expect(
      page.getByRole('heading', { name: /neue belohnung/i }),
    ).toBeVisible();
    // Fill minimal fields — use flutterFill-style hot path directly
    const nameField = page.getByRole('textbox', { name: /name/i });
    await nameField.click();
    await nameField.evaluate(() => new Promise((r) => setTimeout(r, 150)));
    await nameField.pressSequentially('Tab-Test-Reward', { delay: 30 });
    const priceField = page.getByRole('textbox', { name: /preis/i });
    await priceField.click();
    await priceField.evaluate(() => new Promise((r) => setTimeout(r, 150)));
    await priceField.pressSequentially('10', { delay: 30 });
    await page.getByRole('button', { name: 'Speichern' }).click();

    // Back on the reward list — the new reward is visible
    await expect(
      page.getByRole('heading', { name: /belohnungen verwalten/i }),
    ).toBeVisible();
    await expect(
      page.getByRole('group', { name: /tab-test-reward/i }),
    ).toBeVisible();

    // Switch to Home
    await clickTab(page, 'Home');
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    // Switch back to Rewards — provider state preserved, card still there
    await clickTab(page, 'Rewards');
    await expect(
      page.getByRole('group', { name: /tab-test-reward/i }),
    ).toBeVisible();
  });

  test('TC-016.3 — Child: alle 5 Tabs wechseln', async ({ seededPage }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
    });

    // Starts on Home
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await clickTab(page, 'Quests');
    await expect(
      page.getByRole('heading', { name: /quest board/i }),
    ).toBeVisible();

    await clickTab(page, 'Rewards');
    await expect(
      page.getByRole('heading', { name: /meine belohnungen/i }),
    ).toBeVisible();

    await clickTab(page, 'Shop');
    await expect(
      page.getByRole('heading', { name: 'Shop' }),
    ).toBeVisible();

    await clickTab(page, 'Profil');
    await expect(
      page.getByRole('button', { name: /abmelden.*ausloggen/i }),
    ).toBeVisible();

    // Back to Home
    await clickTab(page, 'Home');
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();
  });

  test('TC-016.4 — Logout räumt last_user_id auf und leitet zu /login', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithChild());

    // Before logout: last_user_id set to Mama
    const beforeRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(beforeRaw).toBe(JSON.stringify(IDS.parentMamaId));

    await clickTab(page, 'Profil');
    await page
      .getByRole('button', { name: /abmelden.*ausloggen/i })
      .click();
    await expect(page).toHaveURL(/#\/login/);

    const afterRaw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(afterRaw).toBeNull();
  });

  test.skip('TC-016.5 — Wiedereinloggen als Child öffnet Hero-Home (covered by PW-003 TC-003.5)',
      () => {
    // The full logout → select different avatar → land on the correct
    // dashboard flow is already asserted in
    // PW-003-login-user-switching.spec.ts TC-003.5. Kept as a
    // documentation-only skip to make the cross-reference explicit.
  });

  test('TC-016.6 — Browser-Refresh erhält die Authentifizierung', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithChild());
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    await page.reload();

    // After reload, re-activate semantics (not done automatically by
    // the fixture on a raw reload).
    await page.locator('flt-semantics-placeholder').dispatchEvent('click');

    // Still authenticated as Mama, still on parent-dashboard
    await expect(page).toHaveURL(/#\/parent-dashboard/);
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    // last_user_id still persisted
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.last_user_id'),
    );
    expect(raw).toBe(JSON.stringify(IDS.parentMamaId));
  });
});
