/**
 * Verify-Test für das Seed-Fixture (nicht Teil der PW-NNN Reihe).
 *
 * Beweist, dass:
 *   1. `applySeed()` VIA `page.addInitScript()` früh genug läuft, damit
 *      Flutter den Seed-State beim ersten Read sieht.
 *   2. Jeder einzelne Fixture-Builder valide Seed-Daten produziert, die
 *      das Dart-Model-Parsing überleben.
 *   3. Das App-Routing den Seed-State korrekt interpretiert.
 *
 * Falls ein Test hier fehlschlägt, ist der Seed für alle nachfolgenden
 * PW-NNN-Tests kaputt → FIRST fix the seed, THEN move on.
 */

import { test, expect } from '../fixtures';
import {
  seedFreshApp,
  seedFamilyWithParent,
  seedFamilyWithChild,
  seedFamilyWithQuestAndReward,
  seedChildWithApprovedQuest,
} from '../fixtures/seed';

test.describe('seed fixture', () => {
  test('freshApp routes to family setup', async ({ seededPage }) => {
    const page = await seededPage(seedFreshApp());
    await expect(
      page.getByRole('heading', { name: /familie einrichten/i }),
    ).toBeVisible();
  });

  test('familyWithParent routes to parent dashboard', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithParent());
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();
  });

  test('familyWithChild renders hero progress in parent dashboard', async ({ seededPage }) => {
    const page = await seededPage(seedFamilyWithChild());
    // Parent is logged in, dashboard shows Luca's hero
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();
    // Luca's progress bar should be rendered (label contains Luca + Lvl 1)
    await expect(
      page.getByRole('progressbar', { name: /luca.*lvl\s*1/i }),
    ).toBeVisible();
  });

  test('familyWithQuestAndReward exposes the seeded quest in parent quest management', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithQuestAndReward());
    // Navigate to Quests tab
    await page.getByRole('button', { name: /^quests$/i }).click();
    await expect(
      page.getByRole('heading', { name: /quest.*verwaltung/i }),
    ).toBeVisible();
    // Seeded quest "Zimmer aufräumen" should be visible
    await expect(page.getByText('Zimmer aufräumen')).toBeVisible();
  });

  test('childWithApprovedQuest routes to parent dashboard and persists seeded storage', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedChildWithApprovedQuest());

    // Parent „Mama" is logged in (last_user_id = mama)
    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    // We cannot assert Luca's balance via the parent dashboard UI: the
    // dashboard reads `pointsProvider.balance(child.id)`, but
    // `PointsProvider.loadData()` is never called during bootstrap
    // (see docs/IST_ANALYSE.md §5.2). That's a real app gap, not a seed
    // problem. Instead, we assert the raw localStorage contents so the
    // seed can still be verified end-to-end.
    const storage = await page.evaluate(() => ({
      pointsAccounts: window.localStorage.getItem('flutter.points_accounts'),
      transactions: window.localStorage.getItem('flutter.transactions'),
      heroes: window.localStorage.getItem('flutter.heroes'),
      questInstances: window.localStorage.getItem('flutter.quest_instances'),
    }));

    // Each value is double-JSON-encoded (shared_preferences_web format).
    // Parsing once gives the inner JSON string, parsing twice gives the
    // actual list/object.
    const decode = (raw: string | null) =>
      raw === null ? null : JSON.parse(JSON.parse(raw));

    const accounts = decode(storage.pointsAccounts) as Array<{ userId: string; balance: number }>;
    expect(accounts.find((a) => a.userId === 'user-luca-001')?.balance).toBe(10);

    const heroes = decode(storage.heroes) as Array<{ userId: string; currentStreak: number; currentXP: number }>;
    const lucaHero = heroes.find((h) => h.userId === 'user-luca-001');
    expect(lucaHero?.currentXP).toBe(50);
    expect(lucaHero?.currentStreak).toBe(1);

    const qis = decode(storage.questInstances) as Array<{ status: string }>;
    expect(qis[0]?.status).toBe('completed');
  });
});
