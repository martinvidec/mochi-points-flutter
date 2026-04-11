# Mochi Points — Repo-wide command shortcuts.
#
# The Flutter CLI is the single source of truth for day-to-day work
# (flutter pub get / flutter run / flutter test / flutter build). This
# Makefile exists only to provide a single entry point for cross-tool
# targets the Flutter CLI cannot handle itself — currently the
# Playwright E2E suite under e2e/.

.PHONY: e2e e2e-headed e2e-debug e2e-install

## Run the full Playwright E2E suite (headless, via the e2e/ project).
## The Playwright config starts `flutter run -d web-server` on port 8080
## automatically if nothing is listening.
e2e:
	cd e2e && npm install && npx playwright install chromium && npm test

## Run the suite headed — useful for debugging locator mismatches.
e2e-headed:
	cd e2e && npm install && npx playwright install chromium && npm run test:headed

## Open the Playwright Inspector (PWDEBUG=1).
e2e-debug:
	cd e2e && npm install && npx playwright install chromium && npm run test:debug

## Install e2e/ dependencies only (useful as a separate CI step).
e2e-install:
	cd e2e && npm install && npx playwright install chromium
