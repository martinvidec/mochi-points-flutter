/**
 * PW-006 — Child: Quest akzeptieren & erledigen
 *
 * Source spec: docs/tests/playwright/PW-006-child-quest-lifecycle.md
 * IST-Analyse process: P5 (Child-Pfad)
 * Tracking issue: #170
 *
 * Covers the child's quest lifecycle:
 *   - Quest board shows available quests
 *   - Accept a quest (status: inProgress)
 *   - Mark as done (status: pendingApproval)
 *   - Parent notification is created
 *   - No double-acceptance possible
 *
 * Child bottom nav: Home, Quests, Rewards, Shop, Profil
 *
 * Quest card accessible name pattern:
 *   "<Name> <Rarity> <Status> <Description> <Points> Punkte <XP> XP"
 *   Status: "Verfügbar" / "In Bearbeitung"
 *
 * Quest detail page:
 *   - heading "Quest Details"
 *   - button "Quest annehmen" (available quest)
 *   - button "Als erledigt markieren" (in-progress quest)
 *
 * Quest board:
 *   - heading "Quest Board"
 *   - tabs: "Alle", "Daily", "Weekly", "Epic", "Series"
 *   - sections: "Aktive Quests", "Verfügbare Quests"
 */

import { test, expect } from '../fixtures';
import { flutterText } from '../fixtures/flutter';
import { seedFamilyWithQuestAndReward, IDS } from '../fixtures/seed';

/** Seed as child Luca (not Mama). */
function childSeed() {
  return {
    ...seedFamilyWithQuestAndReward(),
    lastUserId: IDS.childLucaId,
  };
}

test.describe('PW-006 Child: Quest akzeptieren & erledigen', () => {
  test('TC-006.1 — Quest-Board zeigt verfügbare Quest', async ({
    seededPage,
  }) => {
    const page = await seededPage(childSeed());

    // Child lands on hero-home
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Navigate to Quest Board via bottom nav
    await page.getByRole('button', { name: 'Quests', exact: true }).click();
    await expect(
      page.getByRole('heading', { name: /quest board/i }),
    ).toBeVisible();

    // "Verfügbare Quests" section is visible
    await expect(page.getByText('Verfügbare Quests')).toBeVisible();

    // "Zimmer aufräumen" appears as an available quest
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen.*verfügbar/i }),
    ).toBeVisible();

    // No active quests section (no in-progress instances)
    await expect(page.getByText('Aktive Quests')).toHaveCount(0);
  });

  test('TC-006.2 — Quest annehmen', async ({ seededPage }) => {
    const page = await seededPage(childSeed());

    // Click the quest card on hero-home to open detail
    await page
      .getByRole('button', { name: /zimmer aufräumen.*verfügbar/i })
      .click();
    await expect(
      page.getByRole('heading', { name: /quest details/i }),
    ).toBeVisible();

    // Accept the quest
    await page.getByRole('button', { name: 'Quest annehmen' }).click();

    // Snackbar confirmation
    await expect(
      flutterText(page, /quest angenommen/i),
    ).toBeVisible();

    // Back on hero-home, quest shows "In Bearbeitung" status
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen.*in bearbeitung/i }),
    ).toBeVisible();

    // Verify localStorage: quest_instances has one entry with status inProgress
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quest_instances'),
    );
    expect(raw).not.toBeNull();
    const instances = JSON.parse(JSON.parse(raw!));
    expect(instances).toHaveLength(1);
    expect(instances[0].status).toBe('inProgress');
    expect(instances[0].childId).toBe(IDS.childLucaId);
  });

  test('TC-006.3 — Quest als erledigt markieren', async ({ seededPage }) => {
    const page = await seededPage(childSeed());

    // Accept the quest first
    await page
      .getByRole('button', { name: /zimmer aufräumen.*verfügbar/i })
      .click();
    await page.getByRole('button', { name: 'Quest annehmen' }).click();
    await expect(
      flutterText(page, /quest angenommen/i),
    ).toBeVisible();

    // Now click the in-progress quest to open detail
    await page
      .getByRole('button', { name: /zimmer aufräumen.*in bearbeitung/i })
      .click();
    await expect(
      page.getByRole('heading', { name: /quest details/i }),
    ).toBeVisible();

    // Mark as done
    await page
      .getByRole('button', { name: 'Als erledigt markieren' })
      .click();

    // Snackbar confirmation
    await expect(
      flutterText(page, /quest als erledigt markiert/i),
    ).toBeVisible();

    // Back on hero-home, no active quests
    await expect(page.getByText('Keine aktiven Quests')).toBeVisible();

    // Verify localStorage: instance status is pendingApproval
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.quest_instances'),
    );
    const instances = JSON.parse(JSON.parse(raw!));
    expect(instances[0].status).toBe('pendingApproval');
    expect(instances[0].completedAt).not.toBeNull();
  });

  test('TC-006.4 — Parent-Benachrichtigung entsteht', async ({
    seededPage,
  }) => {
    const page = await seededPage(childSeed());

    // Accept + complete quest
    await page
      .getByRole('button', { name: /zimmer aufräumen.*verfügbar/i })
      .click();
    await page.getByRole('button', { name: 'Quest annehmen' }).click();
    await expect(
      flutterText(page, /quest angenommen/i),
    ).toBeVisible();

    await page
      .getByRole('button', { name: /zimmer aufräumen.*in bearbeitung/i })
      .click();
    await page
      .getByRole('button', { name: 'Als erledigt markieren' })
      .click();
    await expect(
      flutterText(page, /quest als erledigt markiert/i),
    ).toBeVisible();

    // Verify notification was created for parent
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    expect(raw).not.toBeNull();
    const notifications = JSON.parse(JSON.parse(raw!));
    const questNotif = notifications.find(
      (n: { type: string }) => n.type === 'questCompleted',
    );
    expect(questNotif).toBeTruthy();
    expect(questNotif.userId).toBe(IDS.parentMamaId);
    expect(questNotif.title).toContain('Genehmigung');
    expect(questNotif.isRead).toBe(false);
  });

  test('TC-006.5 — Keine Doppel-Annahme möglich', async ({ seededPage }) => {
    const page = await seededPage(childSeed());

    // Accept the quest
    await page
      .getByRole('button', { name: /zimmer aufräumen.*verfügbar/i })
      .click();
    await page.getByRole('button', { name: 'Quest annehmen' }).click();
    await expect(
      flutterText(page, /quest angenommen/i),
    ).toBeVisible();

    // Navigate to Quest Board
    await page.getByRole('button', { name: 'Quests', exact: true }).click();
    await expect(
      page.getByRole('heading', { name: /quest board/i }),
    ).toBeVisible();

    // "Verfügbare Quests" section should be empty or not contain "Zimmer aufräumen"
    // The quest moved from "Verfügbar" to "Aktive Quests"
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen.*verfügbar/i }),
    ).toHaveCount(0);

    // Quest appears in "Aktive Quests" section instead
    await expect(page.getByText('Aktive Quests')).toBeVisible();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen.*in bearbeitung/i }),
    ).toBeVisible();
  });

  test('TC-006.6 — Filter-Tabs im Quest-Board', async ({ seededPage }) => {
    const page = await seededPage(childSeed());

    // Navigate to Quest Board
    await page.getByRole('button', { name: 'Quests', exact: true }).click();
    await expect(
      page.getByRole('heading', { name: /quest board/i }),
    ).toBeVisible();

    // "Alle" tab is selected by default, quest is visible
    await expect(
      page.getByRole('tab', { name: 'Alle' }),
    ).toHaveAttribute('aria-selected', 'true');
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toBeVisible();

    // "Daily" tab — quest is daily, so it should show
    await page.getByRole('tab', { name: 'Daily' }).click();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toBeVisible();

    // "Weekly" tab — no weekly quests, empty
    await page.getByRole('tab', { name: 'Weekly' }).click();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toHaveCount(0);

    // "Epic" tab — no epic quests, empty
    await page.getByRole('tab', { name: 'Epic' }).click();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toHaveCount(0);

    // Back to "Alle" — quest visible again
    await page.getByRole('tab', { name: 'Alle' }).click();
    await expect(
      page.getByRole('button', { name: /zimmer aufräumen/i }),
    ).toBeVisible();
  });
});
