/**
 * Flutter-Web-spezifische Helpers.
 *
 * Flutter Web rendert in ein <canvas>. DOM-Locators finden nur dann etwas,
 * wenn die Flutter-Semantics-Tree aktiviert ist. Flutter versteckt dafür
 * einen `<flt-semantics-placeholder>`, der per Klick die Semantics aktiviert.
 *
 * Dieses Modul exportiert:
 *   - openFlutterApp(): Navigation + Boot + Semantics-Aktivierung
 *   - flutterFill():    robuster Text-Input für Flutter-Textfelder
 *   - flutterText():    Text-Matcher ohne ARIA-Announcement-Duplicates
 *   - clickUnlabeledButton(): IconButton ohne Semantics-Label klicken
 *
 * Diese Helpers sind das Ergebnis empirischer Recherche während der
 * Implementierung von PW-001 / PW-002 — siehe Kommentare an den einzelnen
 * Funktionen für die Hintergründe.
 */

import type { Locator, Page } from '@playwright/test';

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

/**
 * Schreibt Text in ein Flutter-Textfeld.
 *
 * Flutter Web rendert Textfelder als `<flt-semantics role="textbox">`-
 * Accessibility-Proxy plus ein verstecktes `<input>`, das nur beim Tap
 * auf den Semantics-Knoten gemountet wird. Playwrights `locator.fill()`
 * setzt den DOM-Value direkt, umgeht damit Flutters Texteditor und
 * hinterlässt das Feld effektiv leer. Wir müssen stattdessen echte
 * Keystrokes via `pressSequentially` emittieren.
 *
 * Zwei weitere Stolpersteine:
 *   1. Auf Sub-Pages (z. B. AddMemberPage) auto-fokussiert Flutter das
 *      erste Textfeld, ein expliziter `.click()` würde den Fokus direkt
 *      wieder abschalten. Wir klicken trotzdem, da Playwright beim
 *      Click das Feld stabil re-fokussiert und das versteckte `<input>`
 *      final mountet.
 *   2. Das versteckte `<input>` braucht nach dem Mount ein paar Frames,
 *      bevor es Keystrokes annimmt — sonst wird das erste Zeichen
 *      geschluckt. 150 ms Settle + 30 ms pro Key ist empirisch stabil.
 */
export async function flutterFill(field: Locator, value: string): Promise<void> {
  await field.click();
  // Deliberate mechanical settle time — not a state-polling sleep.
  await field.evaluate(() => new Promise((r) => setTimeout(r, 150)));
  await field.pressSequentially(value, { delay: 30 });
}

/**
 * Matcht Text im Flutter-Semantics-Tree und ignoriert die
 * `<flt-announcement-polite>` / `<flt-announcement-assertive>`-
 * Live-Regions, die Flutter parallel für Screenreader emittiert.
 *
 * Validierungs-Fehler und Snackbars werden SOWOHL als sichtbare
 * `<span>`-Elemente im Semantics-Tree als AUCH in den Live-Regions
 * gerendert. Ein normales `page.getByText(...)` matched beide und
 * löst Playwrights strict-mode mit „resolved to 2 elements" aus.
 * Dieser Helper scoped auf den Semantics-Tree und blendet die
 * Live-Regions aus.
 */
export function flutterText(page: Page, text: string | RegExp): Locator {
  return page.locator('flt-semantics').getByText(text);
}

/**
 * Klickt den ersten Button innerhalb eines Scopes, der keinen
 * accessible name (`textContent.trim() === ''`) hat.
 *
 * Wichtig: `<flt-semantics role="button">`-Knoten tragen **kein**
 * `aria-label`-Attribut. Der accessible name kommt aus
 * `textContent`. Ein unlabeled IconButton erscheint daher als Button
 * mit leerem `textContent` — darauf filtern wir.
 *
 * Sobald die App den betroffenen IconButton in
 * `Semantics(label: 'Mitglied entfernen: …')` einpackt, kann dieser
 * Helper durch einen normalen `getByRole('button', { name: … })`
 * ersetzt werden.
 */
export async function clickUnlabeledButton(scope: Locator): Promise<void> {
  const buttons = scope.getByRole('button');
  const count = await buttons.count();
  for (let i = 0; i < count; i++) {
    const btn = buttons.nth(i);
    const text = (await btn.textContent()) ?? '';
    if (text.trim() === '') {
      await btn.click();
      return;
    }
  }
  throw new Error('no unlabeled button found in the given scope');
}
