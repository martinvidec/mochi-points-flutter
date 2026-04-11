/**
 * Kombinierte Playwright-Fixture für alle Mochi-Points-Specs.
 *
 * Bietet:
 *   - `flutterPage`: eine Page mit bereits gebooteter Flutter-App und
 *     aktivierter Semantics-Tree. Kein Seed.
 *   - `seededPage`: Factory-Funktion, die erst den localStorage-Seed setzt
 *     und dann Flutter bootet. Nutze diese Variante, wenn dein Test einen
 *     bestimmten Vorzustand braucht.
 *
 * Verwendung in einer Spec:
 *
 *   import { test, expect } from '../fixtures';
 *   import { seedFamilyWithChild } from '../fixtures/seed';
 *
 *   test('happy path', async ({ seededPage }) => {
 *     const page = await seededPage(seedFamilyWithChild());
 *     await expect(page.getByRole('heading', { name: /hallo/i })).toBeVisible();
 *   });
 */

import { test as base, expect, type Page } from '@playwright/test';
import { openFlutterApp } from './flutter';
import { applySeed, type SeedPayload } from './seed';

type SeededPageFactory = (seed: SeedPayload, path?: string) => Promise<Page>;

interface Fixtures {
  flutterPage: Page;
  seededPage: SeededPageFactory;
}

export const test = base.extend<Fixtures>({
  flutterPage: async ({ page }, use) => {
    await openFlutterApp(page);
    await use(page);
  },

  seededPage: async ({ page }, use) => {
    const factory: SeededPageFactory = async (seed, path) => {
      await applySeed(page, seed);
      await openFlutterApp(page, { path });
      return page;
    };
    await use(factory);
  },
});

export { expect };
