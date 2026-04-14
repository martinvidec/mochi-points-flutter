/**
 * PW-013 — Hero-Appearance-Customization
 *
 * Source spec: docs/tests/playwright/PW-013-hero-appearance.md
 * IST-Analyse process: P8 (Avatar)
 * Tracking issue: #177
 *
 * Covers the child's avatar customization flow: open page, change options,
 * save, verify persistence.
 *
 * Semantics findings:
 *   - Page heading: "Hero anpassen"
 *   - Navigation: hero-home → tap hero card (or Profil → "Profil bearbeiten")
 *   - All appearance categories rendered as ChoiceChips
 *     (role=checkbox per F-21): "Kurz/Lang/Lockig/Zopf", etc.
 *   - Save button: unlabeled Icons.check in AppBar (F-23 pattern —
 *     `h2 + flt-semantics[role="button"]`)
 *   - Category options (German labels):
 *       Hautfarbe: Hell · Mittel · Dunkel
 *       Frisur: Kurz · Lang · Lockig · Zopf
 *       Haarfarbe: Braun · Blond · Schwarz · Rot
 *       Outfit: Casual · Sportlich · Schick · Abenteurer
 *       Accessoire: Keins · Brille · Hut · Schal
 *       Haustier: Keins · Katze · Hund · Drache
 *
 * Spec adjustments (documented in-spec comments):
 *   - TC-013.4 (locked items) — not implemented in UI, skipped
 *   - TC-013.5 (equippedItems toggle) — not implemented in UI, skipped
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import { flutterText } from '../fixtures/flutter';
import { seedFamilyWithChild, IDS } from '../fixtures/seed';

function childSeed() {
  return { ...seedFamilyWithChild(), lastUserId: IDS.childLucaId };
}

/** Click the AppBar save button (unlabeled Icons.check next to heading). */
async function clickSaveButton(page: Page): Promise<void> {
  await expect(
    page.getByRole('heading', { name: /hero anpassen/i }),
  ).toBeVisible();
  // Per F-23: the save button is the first flt-semantics[role="button"]
  // immediately after the <h2> heading.
  await page.locator('h2 + flt-semantics[role="button"]').click();
}

/** Open the HeroCustomizationPage from hero-home by tapping the hero card. */
async function openCustomizationViaHeroCard(page: Page): Promise<void> {
  // Hero card has the F-12 accessible name.
  await page
    .getByRole('button', { name: /luca.*level\s*1.*mochi novice/i })
    .click();
  await expect(
    page.getByRole('heading', { name: /hero anpassen/i }),
  ).toBeVisible();
}

test.describe('PW-013 Hero-Appearance-Customization', () => {
  test('TC-013.1 — Appearance-Seite öffnen & Preview sichtbar', async ({
    seededPage,
  }) => {
    const page = await seededPage(childSeed());
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    await openCustomizationViaHeroCard(page);

    // "Hero Name" textbox is the editable name field
    await expect(
      page.getByRole('textbox', { name: /hero name/i }),
    ).toBeVisible();

    // Each category is a group with the matching title
    await expect(
      page.getByRole('group', { name: 'Hautfarbe' }),
    ).toBeVisible();
    await expect(
      page.getByRole('group', { name: 'Frisur' }),
    ).toBeVisible();
    await expect(
      page.getByRole('group', { name: 'Haarfarbe' }),
    ).toBeVisible();
    await expect(
      page.getByRole('group', { name: 'Outfit' }),
    ).toBeVisible();

    // Default selections match the seed ("short" hair, "casual" outfit, …)
    await expect(
      page.getByRole('checkbox', { name: 'Kurz' }),
    ).toBeChecked();
    await expect(
      page.getByRole('checkbox', { name: 'Casual' }),
    ).toBeChecked();
  });

  test('TC-013.2 — Frisur-Auswahl wechselt die ChoiceChip-Selection',
      async ({ seededPage }) => {
    const page = await seededPage(childSeed());
    await openCustomizationViaHeroCard(page);

    // Initial: "Kurz" is checked
    await expect(
      page.getByRole('checkbox', { name: 'Kurz' }),
    ).toBeChecked();

    // Switch to "Lang"
    await page.getByRole('checkbox', { name: 'Lang' }).click();
    await expect(
      page.getByRole('checkbox', { name: 'Lang' }),
    ).toBeChecked();
    await expect(
      page.getByRole('checkbox', { name: 'Kurz' }),
    ).not.toBeChecked();
  });

  test('TC-013.3 — Änderungen speichern & persistent', async ({
    seededPage,
  }) => {
    const page = await seededPage(childSeed());
    await openCustomizationViaHeroCard(page);

    // Change hair style to "Lang" and outfit to "Sportlich"
    await page.getByRole('checkbox', { name: 'Lang' }).click();
    await page.getByRole('checkbox', { name: 'Sportlich' }).click();

    // Save via AppBar check button
    await clickSaveButton(page);

    // Verify persistence in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.heroes'),
    );
    expect(raw).not.toBeNull();
    const heroes = JSON.parse(JSON.parse(raw!));
    expect(heroes[0].appearance.hairStyle).toBe('long');
    expect(heroes[0].appearance.outfit).toBe('sporty');

    // The other fields should remain at their seeded defaults
    expect(heroes[0].appearance.baseAvatar).toBe('default');
    expect(heroes[0].appearance.skinColor).toBe('light');
    expect(heroes[0].appearance.hairColor).toBe('brown');
  });

  test.skip('TC-013.4 — Gesperrte Items nicht auswählbar (UI nicht implementiert)',
      () => {
    // HeroCustomizationPage does not consult `hero.unlockedItems`;
    // all ChoiceChips are always enabled. The gating would need an
    // app-side feature before this test can be written. See spec.
  });

  test.skip('TC-013.5 — Item equippen/unequippen (UI nicht implementiert)',
      () => {
    // There is no UI to toggle `hero.equippedItems`. The Hero model
    // supports it, but the customization page only writes the
    // HeroAppearance subfields. Skipped until a feature exists.
  });
});
