/**
 * PW-002 — Familie einrichten (Onboarding)
 *
 * Source spec: docs/tests/playwright/PW-002-family-onboarding.md
 * IST-Analyse process: P2 (docs/IST_ANALYSE.md §3 / P2)
 * Tracking issue: #166
 *
 * Walks the 3-step Stepper in `FamilySetupPage`:
 *   1. "1 Familienname" — textbox "Familienname" + Weiter
 *   2. "2 Elternteil erstellen" — sub-page AddMemberPage with
 *      textbox "Name", textbox "PIN (optional)", button "Speichern"
 *   3. "3 Weitere Mitglieder" — button "Mitglied hinzufügen" + Fertig
 *
 * After "Fertig" the app calls `pushReplacementNamed('/login')` —
 * the first parent is NOT auto-logged in (see spec UI-Hinweise).
 *
 * All UI labels, validation messages and the unlabeled remove button
 * below were snapshotted live via playwright-cli before writing.
 */

import { test, expect } from '../fixtures';
import { clickUnlabeledButton, flutterFill, flutterText } from '../fixtures/flutter';
import { seedFreshApp } from '../fixtures/seed';

test.describe('PW-002 Familie einrichten', () => {
  test('TC-002.1 — happy path: family + first parent + child routes to login', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFreshApp());

    // Step 1 — family name
    await expect(
      page.getByRole('heading', { name: /familie einrichten/i }),
    ).toBeVisible();
    await flutterFill(
      page.getByRole('textbox', { name: 'Familienname' }),
      'Test-Familie',
    );
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    // Step 2 — first parent (AddMemberPage sub-route)
    await page
      .getByRole('button', { name: 'Elternteil erstellen', exact: true })
      .click();
    await expect(
      page.getByRole('heading', { name: /elternteil erstellen/i }),
    ).toBeVisible();
    await flutterFill(page.getByRole('textbox', { name: 'Name' }), 'Mama');
    await flutterFill(
      page.getByRole('textbox', { name: /pin \(optional\)/i }),
      '1234',
    );
    await page.getByRole('button', { name: 'Speichern' }).click();

    // Back on the stepper with the new parent listed
    await expect(page.getByRole('group', { name: /mama.*eltern/i })).toBeVisible();
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    // Step 3 — optional child
    await page.getByRole('button', { name: 'Mitglied hinzufügen' }).click();
    await expect(
      page.getByRole('heading', { name: /mitglied hinzufügen/i }),
    ).toBeVisible();
    await flutterFill(page.getByRole('textbox', { name: 'Name' }), 'Luca');
    await page.getByRole('button', { name: 'Kind' }).click();
    await page.getByRole('button', { name: 'Speichern' }).click();
    await expect(page.getByRole('group', { name: /luca.*kind/i })).toBeVisible();

    // Finish — expect navigation to /login (NOT auto-login to dashboard)
    await page.getByRole('button', { name: 'Fertig' }).click();

    await expect(page).toHaveURL(/#\/login/);
    await expect(page.getByText(/wer bist du\?/i)).toBeVisible();
    await expect(
      page.getByRole('button', { name: /mama.*eltern/i }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: /luca.*kind/i }),
    ).toBeVisible();

    // Raw storage: family + members persisted, but no last_user_id
    const keys = await page.evaluate(() => ({
      family: window.localStorage.getItem('flutter.family'),
      members: window.localStorage.getItem('flutter.family_members'),
      lastUserId: window.localStorage.getItem('flutter.last_user_id'),
    }));
    expect(keys.family).not.toBeNull();
    expect(keys.members).not.toBeNull();
    expect(keys.lastUserId).toBeNull();
  });

  test('TC-002.2 — empty family name shows validation error', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFreshApp());

    // Click "Weiter" on step 1 without filling the textbox
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    // Inline validation error under the empty textbox
    await expect(
      flutterText(page, /bitte familiennamen eingeben/i),
    ).toBeVisible();

    // Still on step 1 — URL unchanged and step 2 controls not visible
    await expect(page).toHaveURL(/#\/family-setup/);
    await expect(
      page.getByRole('button', { name: 'Elternteil erstellen', exact: true }),
    ).toHaveCount(0);
  });

  test('TC-002.3 — advancing without a first parent shows validation error', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFreshApp());

    // Step 1 — valid family name
    await flutterFill(
      page.getByRole('textbox', { name: 'Familienname' }),
      'Test-Familie',
    );
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    // Step 2 — click "Weiter" without creating a parent
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    await expect(
      flutterText(page, /bitte einen elternteil erstellen/i),
    ).toBeVisible();

    // Still on step 2, no navigation
    await expect(page).toHaveURL(/#\/family-setup/);
  });

  test('TC-002.4 — members added in step 3 can be removed before finishing', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFreshApp());

    // Walk steps 1 + 2 to get to step 3 with a parent in place
    await flutterFill(
      page.getByRole('textbox', { name: 'Familienname' }),
      'Test-Familie',
    );
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();
    await page
      .getByRole('button', { name: 'Elternteil erstellen', exact: true })
      .click();
    await flutterFill(page.getByRole('textbox', { name: 'Name' }), 'Mama');
    await page.getByRole('button', { name: 'Speichern' }).click();
    await page.getByRole('button', { name: 'Weiter', exact: true }).click();

    // Add child "Luca"
    await page.getByRole('button', { name: 'Mitglied hinzufügen' }).click();
    await flutterFill(page.getByRole('textbox', { name: 'Name' }), 'Luca');
    await page.getByRole('button', { name: 'Kind' }).click();
    await page.getByRole('button', { name: 'Speichern' }).click();

    const lucaGroup = page.getByRole('group', { name: /luca.*kind/i });
    await expect(lucaGroup).toBeVisible();

    // Click the unlabeled delete button inside the member group.
    // TODO(app): wrap the remove IconButton in Semantics(label: 'Mitglied entfernen: …')
    //            so this can become a standard getByRole('button', { name: … }) call.
    await clickUnlabeledButton(lucaGroup);

    // Member is gone, Fertig is still available (step 3 permits zero children)
    await expect(page.getByRole('group', { name: /luca.*kind/i })).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Fertig' })).toBeVisible();
  });
});
