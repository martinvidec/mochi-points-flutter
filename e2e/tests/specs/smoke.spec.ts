/**
 * Smoke-Test für das Playwright-Setup.
 *
 * Dieser Test gehört KEINER Spec PW-001..PW-016 an — sein einziger Zweck
 * ist, in CI und lokal zu beweisen, dass:
 *   1. Die Flutter-Web-App erreichbar ist.
 *   2. Der Engine-Boot funktioniert (`<flt-semantics-placeholder>`).
 *   3. Die Semantics-Tree beim Klick auf den Placeholder aufgebaut wird.
 *
 * Sobald PW-001 (Bootstrap & Routing) implementiert ist, kann dieser Smoke-
 * Test entfallen. Bis dahin fängt er „Build kaputt / Server nicht erreichbar"
 * früh ab, ohne dass ein echter Spec gescheitert aussieht.
 */

import { test, expect } from '../fixtures';

test.describe('smoke', () => {
  test('flutter web app boots and exposes the semantics tree', async ({
    flutterPage,
  }) => {
    // Nach `openFlutterApp` liegt mindestens ein `flt-semantics`-Node im DOM.
    const semantics = flutterPage.locator('flt-semantics').first();
    await expect(semantics).toBeAttached();
  });
});
