/**
 * PW-001 — App Bootstrap & Routing
 *
 * Source spec: docs/tests/playwright/PW-001-bootstrap-routing.md
 * IST-Analyse process: P1 (docs/IST_ANALYSE.md §3 / P1)
 * Tracking issue: #165
 *
 * Covers the four routing decisions that `SplashPage._initialize()` makes
 * based on the persisted state:
 *   1. no family at all → /family-setup
 *   2a. family + logged-in parent → /parent-dashboard
 *   2b. family + logged-in child → /hero-home
 *   3. family exists but no last_user_id → /login
 *
 * All four landing screens were snapshotted live with playwright-cli before
 * writing these tests so the assertions target widgets that actually exist
 * in the semantics tree. See the spec file for empirical notes (e.g.
 * "Wer bist du?" is rendered as generic text, not as a heading).
 */

import { test, expect } from '../fixtures';
import {
  seedFreshApp,
  seedFamilyWithParent,
  seedFamilyWithChild,
  IDS,
} from '../fixtures/seed';

test.describe('PW-001 App Bootstrap & Routing', () => {
  test('TC-001.1 — cold start without a family routes to family setup', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFreshApp());

    // The family setup page shows a level-2 heading "Familie einrichten".
    await expect(
      page.getByRole('heading', { name: /familie einrichten/i }),
    ).toBeVisible();

    // And the stepper's first step button — proves we reached the Stepper,
    // not some intermediate splash.
    await expect(
      page.getByRole('button', { name: /familienname/i }),
    ).toBeVisible();

    // URL hash contains the named route.
    expect(page.url()).toContain('#/family-setup');
  });

  test('TC-001.2a — parent marked as current user routes to parent dashboard', async ({
    seededPage,
  }) => {
    const page = await seededPage(seedFamilyWithParent());

    await expect(
      page.getByRole('heading', { name: /hallo,\s*mama/i }),
    ).toBeVisible();

    expect(page.url()).toContain('#/parent-dashboard');
  });

  test('TC-001.2b — child marked as current user routes to hero home', async ({
    seededPage,
  }) => {
    // seedFamilyWithChild() leaves Mama as `last_user_id`; override to Luca
    // so the splash picks the child branch.
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: IDS.childLucaId,
    });

    // Hero Home renders a level-2 heading "Mochi Hero" and a hero card
    // button whose accessible name combines name + level + title + xp.
    await expect(
      page.getByRole('heading', { name: /mochi hero/i }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: /luca.*level\s*1.*mochi novice/i }),
    ).toBeVisible();

    expect(page.url()).toContain('#/hero-home');
  });

  test('TC-001.3 — family exists but no current user routes to login', async ({
    seededPage,
  }) => {
    // Mirror the real post-family-setup state: family + members persisted,
    // but `last_user_id` was never written.
    const page = await seededPage({
      ...seedFamilyWithChild(),
      lastUserId: null,
    });

    // "Wer bist du?" lives in a generic text node on the login page — so
    // we use getByText instead of getByRole('heading').
    await expect(page.getByText(/wer bist du\?/i)).toBeVisible();

    // Both avatars from the seed are offered. The accessible names follow
    // the pattern "<Initial> <Name> <Rolle>".
    await expect(
      page.getByRole('button', { name: /mama.*eltern/i }),
    ).toBeVisible();
    await expect(
      page.getByRole('button', { name: /luca.*kind/i }),
    ).toBeVisible();

    expect(page.url()).toContain('#/login');
  });
});
