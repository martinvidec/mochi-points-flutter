/**
 * Flutter-Web-spezifische Helpers.
 *
 * Flutter Web rendert in ein <canvas>. DOM-Locators finden nur dann etwas,
 * wenn die Flutter-Semantics-Tree aktiviert ist. Flutter versteckt dafür
 * einen `<flt-semantics-placeholder>`, der per Klick die Semantics aktiviert.
 *
 * `openFlutterApp` kombiniert Navigation, Boot-Abwartung und Semantics-Aktivierung
 * in einen Aufruf. Jedes Test-Fixture soll diese Funktion als ersten Schritt
 * verwenden (siehe `tests/fixtures/index.ts`).
 *
 * Siehe auch:
 *   https://api.flutter.dev/flutter/semantics/SemanticsBinding-class.html
 *   docs/tests/playwright/README.md (Shared-Fixtures & Konventionen)
 */

import type { Page } from '@playwright/test';

export interface OpenFlutterAppOptions {
  /** Pfad (z. B. '/', '#/login') — default '/' */
  path?: string;
  /** Boot-Timeout in ms — default 30 s */
  bootTimeout?: number;
}

/**
 * Navigiert zur Flutter-App, wartet auf den Engine-Boot und aktiviert
 * die Semantics-Tree. Nach dem Aufruf sind role-basierte Locators nutzbar.
 */
export async function openFlutterApp(
  page: Page,
  opts: OpenFlutterAppOptions = {},
): Promise<void> {
  const path = opts.path ?? '/';
  const bootTimeout = opts.bootTimeout ?? 30_000;

  await page.goto(path);

  // Flutter signalisiert Engine-Ready, indem der unsichtbare Semantics-
  // Placeholder im DOM erscheint.
  await page.waitForSelector('flt-semantics-placeholder', {
    state: 'attached',
    timeout: bootTimeout,
  });

  // Der Placeholder liegt bei (-1,-1) außerhalb des Viewports. Ein normaler
  // Click (auch `{force: true}`) scheitert mit „Element is outside of the
  // viewport". `dispatchEvent('click')` umgeht die Actionability-Checks
  // komplett und feuert einen synthetischen Click direkt auf das Element.
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');

  // Verifizieren, dass die Semantics-Tree wirklich ausgebaut wird.
  // Falls das fehlschlägt, wrappt die App nicht genügend Widgets in
  // `Semantics()` und braucht einen App-seitigen Fix (NICHT im Test lösen).
  await page.waitForSelector('flt-semantics', {
    state: 'attached',
    timeout: 5_000,
  });
}
