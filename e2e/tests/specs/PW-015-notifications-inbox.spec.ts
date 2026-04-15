/**
 * PW-015 — Benachrichtigungen (Inbox)
 *
 * Source spec: docs/tests/playwright/PW-015-notifications-inbox.md
 * IST-Analyse process: P10
 * Tracking issue: #179
 *
 * Covers the notification bell + inbox for both parent and child.
 * Unlike most prior specs, notification seeding actually lands in the
 * UI: `NotificationProvider.loadData()` IS called at bootstrap
 * (splash_page.dart:25), so `seed.notifications` is first-class.
 *
 * Semantics findings:
 *   - Bell button is adjacent to the <h2> heading in the AppBar
 *     (F-23 pattern): `h2 + flt-semantics[role="button"]`
 *   - With unread > 0 the bell's accessible name is the count digit
 *     ("3"), without unread it is empty
 *   - Inbox heading: "Benachrichtigungen"
 *   - Mark-all button: "Alle gelesen" (only visible when unread > 0)
 *   - Empty state: "Keine Benachrichtigungen"
 *   - User isolation is enforced by NotificationProvider.userNotifications
 *     filtering on the current user
 */

import type { Page } from '@playwright/test';
import { test, expect } from '../fixtures';
import {
  seedFamilyWithChild,
  IDS,
  type SeedPayload,
} from '../fixtures/seed';

/** Build a notification object for the seed. */
function notif(
  id: string,
  userId: string,
  opts: {
    type: string;
    title: string;
    message: string;
    icon?: string;
    createdAt: string;
    isRead?: boolean;
  },
): object {
  return {
    id,
    userId,
    type: opts.type,
    title: opts.title,
    message: opts.message,
    icon: opts.icon ?? '🔔',
    createdAt: opts.createdAt,
    isRead: opts.isRead ?? false,
  };
}

/** Convenience: ISO timestamp `minutesAgo` minutes before now. */
function minutesAgo(m: number): string {
  return new Date(Date.now() - m * 60_000).toISOString();
}

/** Click the notification bell using the F-23 adjacent-sibling
 *  pattern: the bell is the first `<flt-semantics role="button">`
 *  right after the <h2> AppBar heading.
 *
 *  NOTE: this also matches the AppBar save-button in edit pages, so
 *  only use this on pages that don't have a save button (hero-home,
 *  parent dashboard — both fine). */
async function clickNotificationBell(page: Page): Promise<void> {
  await page.locator('h2 + flt-semantics[role="button"]').click();
  await expect(
    page.getByRole('heading', { name: /benachrichtigungen/i }),
  ).toBeVisible();
}

test.describe('PW-015 Benachrichtigungen (Inbox)', () => {
  test('TC-015.1 — Badge-Zähler zeigt ungelesene (Child)', async ({
    seededPage,
  }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
      notifications: [
        notif('n1', IDS.childLucaId, {
          type: 'questApproved',
          title: 'Quest genehmigt!',
          message: '"Zimmer" wurde genehmigt.',
          createdAt: minutesAgo(5),
        }),
        notif('n2', IDS.childLucaId, {
          type: 'levelUp',
          title: 'Level Up!',
          message: 'Du bist jetzt Level 2!',
          createdAt: minutesAgo(10),
        }),
        notif('n3', IDS.childLucaId, {
          type: 'streakMilestone',
          title: 'Streak Milestone!',
          message: '7 Tage in Folge!',
          createdAt: minutesAgo(15),
        }),
      ],
    });

    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Bell button has the unread count "3" as its accessible name
    await expect(
      page.getByRole('button', { name: '3', exact: true }).first(),
    ).toBeVisible();
  });

  test('TC-015.2 — Inbox listet alle Einträge, neueste zuerst', async ({
    seededPage,
  }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
      notifications: [
        notif('n-old', IDS.childLucaId, {
          type: 'questRejected',
          title: 'Quest abgelehnt',
          message: 'Alte Quest-Ablehnung',
          createdAt: minutesAgo(60),
        }),
        notif('n-mid', IDS.childLucaId, {
          type: 'levelUp',
          title: 'Level Up!',
          message: 'Mittlerer Eintrag',
          createdAt: minutesAgo(30),
        }),
        notif('n-new', IDS.childLucaId, {
          type: 'streakMilestone',
          title: 'Streak Milestone!',
          message: 'Neuester Eintrag',
          createdAt: minutesAgo(5),
        }),
      ],
    });

    await clickNotificationBell(page);

    // All three titles visible
    await expect(page.getByText('Quest abgelehnt')).toBeVisible();
    await expect(page.getByText('Level Up!')).toBeVisible();
    await expect(page.getByText('Streak Milestone!')).toBeVisible();

    // Newest first: "Streak Milestone!" should appear before "Level Up!"
    // in DOM order. Use bounding-box Y to check ordering robustly.
    const newestBox = await page
      .getByText('Streak Milestone!')
      .boundingBox();
    const middleBox = await page.getByText('Level Up!').boundingBox();
    const oldestBox = await page.getByText('Quest abgelehnt').boundingBox();
    expect(newestBox).not.toBeNull();
    expect(middleBox).not.toBeNull();
    expect(oldestBox).not.toBeNull();
    expect(newestBox!.y).toBeLessThan(middleBox!.y);
    expect(middleBox!.y).toBeLessThan(oldestBox!.y);
  });

  test('TC-015.3 — Einzelne Notification als gelesen markieren', async ({
    seededPage,
  }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
      notifications: [
        notif('n1', IDS.childLucaId, {
          type: 'questApproved',
          title: 'Zuerst zu lesen',
          message: 'Tap mich',
          createdAt: minutesAgo(5),
        }),
        notif('n2', IDS.childLucaId, {
          type: 'levelUp',
          title: 'Anderer Eintrag',
          message: 'Bleibt ungelesen',
          createdAt: minutesAgo(10),
        }),
      ],
    });

    // Bell shows "2" initially
    await expect(
      page.getByRole('button', { name: '2', exact: true }).first(),
    ).toBeVisible();

    await clickNotificationBell(page);

    // Tap the first notification by its title
    await page.getByText('Zuerst zu lesen').click();

    // Go back to hero-home
    await page.getByRole('button', { name: 'Zurück' }).click();
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();

    // Badge now shows "1"
    await expect(
      page.getByRole('button', { name: '1', exact: true }).first(),
    ).toBeVisible();

    // Verify isRead in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(raw!));
    expect(
      notifications.find((n: { id: string }) => n.id === 'n1').isRead,
    ).toBe(true);
    expect(
      notifications.find((n: { id: string }) => n.id === 'n2').isRead,
    ).toBe(false);
  });

  test('TC-015.4 — "Alle gelesen" markiert alle als gelesen', async ({
    seededPage,
  }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
      notifications: [
        notif('n1', IDS.childLucaId, {
          type: 'questApproved',
          title: 'Eins',
          message: 'Alles lesen',
          createdAt: minutesAgo(5),
        }),
        notif('n2', IDS.childLucaId, {
          type: 'levelUp',
          title: 'Zwei',
          message: 'Alles lesen',
          createdAt: minutesAgo(10),
        }),
        notif('n3', IDS.childLucaId, {
          type: 'streakMilestone',
          title: 'Drei',
          message: 'Alles lesen',
          createdAt: minutesAgo(15),
        }),
      ],
    });

    await clickNotificationBell(page);

    await page.getByRole('button', { name: 'Alle gelesen' }).click();

    // "Alle gelesen" button disappears when unreadCount is 0
    await expect(
      page.getByRole('button', { name: 'Alle gelesen' }),
    ).toHaveCount(0);

    // Verify all isRead in localStorage
    const raw = await page.evaluate(() =>
      window.localStorage.getItem('flutter.notifications'),
    );
    const notifications = JSON.parse(JSON.parse(raw!));
    for (const n of notifications) {
      expect(n.isRead).toBe(true);
    }
  });

  test('TC-015.5 — Parent sieht eigene Notifications', async ({
    seededPage,
  }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.parentMamaId,
      notifications: [
        notif('n-p1', IDS.parentMamaId, {
          type: 'questCompleted',
          title: 'Quest wartet auf Genehmigung',
          message: 'Luca hat eine Quest erledigt',
          createdAt: minutesAgo(5),
        }),
        notif('n-p2', IDS.parentMamaId, {
          type: 'rewardRedeemed',
          title: 'Reward-Einlösung angefragt',
          message: 'Luca möchte einen Reward einlösen',
          createdAt: minutesAgo(10),
        }),
      ],
    });

    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    // Parent bell shows "2"
    await expect(
      page.getByRole('button', { name: '2', exact: true }).first(),
    ).toBeVisible();

    await clickNotificationBell(page);
    await expect(
      page.getByText('Quest wartet auf Genehmigung'),
    ).toBeVisible();
    await expect(
      page.getByText('Reward-Einlösung angefragt'),
    ).toBeVisible();
  });

  test('TC-015.6 — User-Isolation: Mama sieht Lucas Notifications nicht',
      async ({ seededPage }) => {
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.parentMamaId, // Mama logged in
      notifications: [
        // Mama's:
        notif('m-only-1', IDS.parentMamaId, {
          type: 'questCompleted',
          title: 'Mama-Eintrag 1',
          message: 'nur für mama',
          createdAt: minutesAgo(5),
        }),
        notif('m-only-2', IDS.parentMamaId, {
          type: 'rewardRedeemed',
          title: 'Mama-Eintrag 2',
          message: 'nur für mama',
          createdAt: minutesAgo(10),
        }),
        // Luca's (should NOT show up in Mama's inbox):
        notif('l-only-1', IDS.childLucaId, {
          type: 'questApproved',
          title: 'Luca-Eintrag 1',
          message: 'nur für luca',
          createdAt: minutesAgo(5),
        }),
        notif('l-only-2', IDS.childLucaId, {
          type: 'levelUp',
          title: 'Luca-Eintrag 2',
          message: 'nur für luca',
          createdAt: minutesAgo(10),
        }),
        notif('l-only-3', IDS.childLucaId, {
          type: 'streakMilestone',
          title: 'Luca-Eintrag 3',
          message: 'nur für luca',
          createdAt: minutesAgo(15),
        }),
      ],
    });

    // Mama's badge shows only 2 (her own unread)
    await expect(
      page.getByRole('button', { name: '2', exact: true }).first(),
    ).toBeVisible();

    await clickNotificationBell(page);

    // Mama's entries visible
    await expect(page.getByText('Mama-Eintrag 1')).toBeVisible();
    await expect(page.getByText('Mama-Eintrag 2')).toBeVisible();

    // Luca's are NOT visible
    await expect(page.getByText('Luca-Eintrag 1')).toHaveCount(0);
    await expect(page.getByText('Luca-Eintrag 2')).toHaveCount(0);
    await expect(page.getByText('Luca-Eintrag 3')).toHaveCount(0);
  });
});
