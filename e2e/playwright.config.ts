import { defineConfig, devices } from '@playwright/test';

// Base URL for the Flutter Web app.
// - In CI the workflow builds `build/web`, serves it statically and sets
//   `E2E_BASE_URL=http://127.0.0.1:8080`, so the runner talks to that server
//   instead of spinning up its own.
// - Locally the default is `http://127.0.0.1:8080` and the `webServer` block
//   below starts `flutter run -d web-server` for you on first test.
// - You can also point the runner at any other server (e.g. `python3 -m
//   http.server` against a pre-built `build/web`) via the same env var.
const BASE_URL = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:8080';

export default defineConfig({
  testDir: './tests/specs',
  // Flutter Web boot is noticeably slower than a typical SPA — give each
  // test room to complete. Individual assertions still use the shorter
  // expect timeout.
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,

  reporter: [['list'], ['html', { open: 'never' }]],

  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // WebKit + Flutter Web has CanvasKit quirks. Enable only after
    // the suite is green on Chromium.
    // { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],

  // In CI the workflow builds + serves build/web itself and sets
  // E2E_BASE_URL, so we don't spin up a webServer there.
  //
  // Locally we mirror the CI path: build the app once with
  // `flutter build web`, then serve the static output with `npx serve`.
  // This is deterministic — the server only starts answering on port 8080
  // when the full JS bundle is on disk.
  //
  // We deliberately do NOT use `flutter run -d web-server` here. That
  // command streams compilation output over a debug socket and starts
  // responding with 200 to `/` *before* the JS bundle is ready, which
  // lets Playwright think the server is up and fires test workers into
  // a half-built page — resulting in `flt-semantics-placeholder`
  // timeouts on the first batch of tests. See commit history for the
  // investigation.
  //
  // If you want hot reload while iterating on tests, start
  // `flutter run -d web-server --web-port 8081` yourself in a separate
  // terminal and run the suite with
  // `E2E_BASE_URL=http://127.0.0.1:8081 npm test`.
  webServer: process.env.CI
    ? undefined
    : {
        command:
          'flutter build web --no-tree-shake-icons && npx --yes serve -s ../build/web -l 8080',
        url: BASE_URL,
        reuseExistingServer: true,
        // First run compiles the Flutter Web bundle from scratch and
        // may also download the Flutter Web SDK — be generous.
        timeout: 300_000,
        stdout: 'pipe',
        stderr: 'pipe',
      },
});
