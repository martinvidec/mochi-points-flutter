/**
 * Shared-Preferences-Seeding für Playwright-Tests.
 *
 * Die App persistiert via `shared_preferences` (Version 2.5.x / _web 2.4.3),
 * was auf Flutter Web in `window.localStorage` mit Prefix `flutter.<key>`
 * schreibt. Indem wir VOR dem Flutter-Boot (via `page.addInitScript`)
 * localStorage setzen, starten wir jeden Test mit einem deterministischen
 * Zustand ohne UI-Klicks für Setup.
 *
 * Die hier bereitgestellten Fixture-Builder spiegeln die im
 * `docs/tests/playwright/README.md` definierten Namen:
 *   - freshApp
 *   - familyWithParent
 *   - familyWithChild
 *   - familyWithQuestAndReward
 *   - childWithApprovedQuest
 *
 * # Wire-Format (empirisch verifiziert)
 *
 * `shared_preferences_web` speichert jeden Wert als JSON-codierten String.
 * Da unser `StorageService` intern bereits JSON schreibt (alle Collections
 * via `prefs.setString(key, jsonEncode(...))`), ergibt sich ein doppeltes
 * JSON-Encoding:
 *
 *   localStorage['flutter.family']
 *     = JSON.stringify(JSON.stringify({ id: '...', name: '...' }))
 *     = '"{\"id\":\"...\",\"name\":\"...\"}"'
 *
 * Für primitive Strings (wie `last_user_id`) wird direkt der String in JSON
 * verpackt:
 *
 *   localStorage['flutter.last_user_id']
 *     = JSON.stringify('user-luca-001')
 *     = '"user-luca-001"'
 *
 * Das `set()`-Helper unten kapselt beide Fälle.
 */

import type { Page } from '@playwright/test';

// --- Key-Konstanten (müssen mit lib/services/storage_service.dart + Provider-Keys übereinstimmen) ---
const PREFIX = 'flutter.';
const KEYS = {
  family: 'family',
  familyMembers: 'family_members',
  lastUserId: 'last_user_id',
  quests: 'quests',
  questInstances: 'quest_instances',
  pointsAccounts: 'points_accounts',
  transactions: 'transactions',
  rewards: 'rewards',
  purchases: 'purchases',
  heroes: 'heroes',
  achievements: 'achievements',
  achievementProgress: 'achievement_progress',
  notifications: 'notifications',
  selectedBackground: 'selected_background',
} as const;

// --- ID-Konstanten für Fixture-Zustände (stabil für Assertions) ---
export const IDS = {
  family: 'fam-test-001',
  parentMamaId: 'user-mama-001',
  parentPapaId: 'user-papa-001',
  childLucaId: 'user-luca-001',
  questCleanRoomId: 'quest-clean-001',
  rewardTabletId: 'reward-tablet-001',
  rewardIceId: 'reward-ice-001',
  rewardPremiumId: 'reward-premium-001',
  heroLucaId: 'hero-luca-001',
  pointsAccountLucaId: 'account-luca-001',
} as const;

// --- Builder-Hilfsfunktionen (liefern fertige Domain-Modelle als JS-Objekte) ---

function nowIso(offsetDays = 0): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return d.toISOString();
}

function buildFamily() {
  return {
    id: IDS.family,
    name: 'Test-Familie',
    inviteCode: null,
    createdAt: nowIso(),
  };
}

function buildParent(id: string, name: string, pin: string | null = null) {
  return {
    id,
    familyId: IDS.family,
    name,
    email: '',
    role: 'parent',
    avatarUrl: null,
    pin,
    createdAt: nowIso(),
  };
}

function buildChild(id: string, name: string, pin: string | null = null) {
  return {
    id,
    familyId: IDS.family,
    name,
    email: '',
    role: 'child',
    avatarUrl: null,
    pin,
    createdAt: nowIso(),
  };
}

function buildHero(userId: string, name: string, opts: Partial<{
  level: number;
  currentXP: number;
  currentStreak: number;
  longestStreak: number;
  activityDates: string[];
  lastActiveDate: string | null;
}> = {}) {
  return {
    id: IDS.heroLucaId,
    userId,
    name,
    level: opts.level ?? 1,
    currentXP: opts.currentXP ?? 0,
    xpToNextLevel: 100,
    currentStreak: opts.currentStreak ?? 0,
    longestStreak: opts.longestStreak ?? 0,
    activityDates: opts.activityDates ?? [],
    lastActiveDate: opts.lastActiveDate,
    badges: [],
    unlockedItems: [],
    equippedItems: [],
    appearance: {
      baseAvatar: 'default',
      skinColor: 'light',
      hairStyle: 'short',
      hairColor: 'brown',
      outfit: 'casual',
    },
  };
}

function buildQuest() {
  return {
    id: IDS.questCleanRoomId,
    familyId: IDS.family,
    createdBy: IDS.parentMamaId,
    name: 'Zimmer aufräumen',
    description: 'Räum dein Zimmer auf',
    icon: 'cleaning_services',
    type: 'daily',
    rarity: 'common',
    rewardPoints: 10,
    rewardXP: 50,
    assignedTo: [IDS.childLucaId],
    deadline: null,
    isActive: true,
    createdAt: nowIso(),
    targetCount: null,
    unit: null,
  };
}

function buildRewards() {
  return [
    {
      id: IDS.rewardTabletId,
      familyId: IDS.family,
      createdBy: IDS.parentMamaId,
      name: '30 min Tablet',
      description: 'Extra Tablet-Zeit',
      icon: 'tablet',
      price: 50,
      category: 'privilege',
      stock: null,
      isActive: true,
      createdAt: nowIso(),
    },
    {
      id: IDS.rewardIceId,
      familyId: IDS.family,
      createdBy: IDS.parentMamaId,
      name: 'Eis',
      description: 'Ein Eis deiner Wahl',
      icon: 'icecream',
      price: 20,
      category: 'item',
      stock: 2,
      isActive: true,
      createdAt: nowIso(),
    },
    {
      id: IDS.rewardPremiumId,
      familyId: IDS.family,
      createdBy: IDS.parentMamaId,
      name: 'Premium-Item',
      description: 'Sehr teurer Reward (Negativtest)',
      icon: 'star',
      price: 1000,
      category: 'item',
      stock: null,
      isActive: true,
      createdAt: nowIso(),
    },
  ];
}

function buildPointsAccount(userId: string, balance: number) {
  return {
    userId,
    balance,
    totalEarned: balance,
    totalSpent: 0,
    lastUpdated: nowIso(),
  };
}

// --- Seed-Payload + Applier ---

export interface SeedPayload {
  family?: ReturnType<typeof buildFamily>;
  familyMembers?: Array<object>;
  lastUserId?: string | null;
  quests?: Array<object>;
  questInstances?: Array<object>;
  pointsAccounts?: Array<ReturnType<typeof buildPointsAccount>>;
  transactions?: Array<object>;
  rewards?: Array<object>;
  purchases?: Array<object>;
  heroes?: Array<ReturnType<typeof buildHero>>;
  notifications?: Array<object>;
}

/**
 * Schreibt die Seed-Daten in `localStorage`, BEVOR die Flutter-Engine bootet.
 * Muss vor dem ersten `page.goto(...)` aufgerufen werden.
 *
 * Alle Werte werden als doppelt-JSON-codierte Strings abgelegt, um das
 * Verhalten von `shared_preferences_web` zu spiegeln (siehe Datei-Header).
 */
export async function applySeed(page: Page, payload: SeedPayload): Promise<void> {
  await page.addInitScript((args: { prefix: string; keys: typeof KEYS; data: SeedPayload }) => {
    const { prefix, keys, data } = args;

    // Für Collections: Objekt/Array → JSON → als String → erneut JSON.
    const setObject = (key: string, value: unknown) => {
      const innerJson = JSON.stringify(value);
      window.localStorage.setItem(prefix + key, JSON.stringify(innerJson));
    };

    // Für Strings (z. B. last_user_id): der String ist bereits der innere
    // Wert. shared_preferences verpackt ihn einmal mit JSON.stringify.
    const setString = (key: string, value: string) => {
      window.localStorage.setItem(prefix + key, JSON.stringify(value));
    };

    if (data.family) setObject(keys.family, data.family);
    if (data.familyMembers) setObject(keys.familyMembers, data.familyMembers);
    if (data.lastUserId !== undefined) {
      if (data.lastUserId === null) {
        window.localStorage.removeItem(prefix + keys.lastUserId);
      } else {
        setString(keys.lastUserId, data.lastUserId);
      }
    }
    if (data.quests) setObject(keys.quests, data.quests);
    if (data.questInstances) setObject(keys.questInstances, data.questInstances);
    if (data.pointsAccounts) setObject(keys.pointsAccounts, data.pointsAccounts);
    if (data.transactions) setObject(keys.transactions, data.transactions);
    if (data.rewards) setObject(keys.rewards, data.rewards);
    if (data.purchases) setObject(keys.purchases, data.purchases);
    if (data.heroes) setObject(keys.heroes, data.heroes);
    if (data.notifications) setObject(keys.notifications, data.notifications);
  }, { prefix: PREFIX, keys: KEYS, data: payload });
}

/** Vollständig leerer Zustand (erster App-Start). */
export function seedFreshApp(): SeedPayload {
  return {};
}

/** Familie + Parent „Mama" (PIN 1234), eingeloggt. */
export function seedFamilyWithParent(): SeedPayload {
  const mama = buildParent(IDS.parentMamaId, 'Mama', '1234');
  return {
    family: buildFamily(),
    familyMembers: [mama],
    lastUserId: mama.id,
  };
}

/** Parent „Mama" (PIN 1234) + Child „Luca", Parent eingeloggt. Child-Hero existiert auf Level 1. */
export function seedFamilyWithChild(): SeedPayload {
  const mama = buildParent(IDS.parentMamaId, 'Mama', '1234');
  const luca = buildChild(IDS.childLucaId, 'Luca');
  return {
    family: buildFamily(),
    familyMembers: [mama, luca],
    lastUserId: mama.id,
    heroes: [buildHero(luca.id, 'Luca')],
    pointsAccounts: [buildPointsAccount(luca.id, 0)],
  };
}

/** familyWithChild + eine Quest + drei Rewards. */
export function seedFamilyWithQuestAndReward(): SeedPayload {
  const base = seedFamilyWithChild();
  return {
    ...base,
    quests: [buildQuest()],
    rewards: buildRewards(),
  };
}

/**
 * Luca hat eine bereits abgeschlossene+genehmigte Quest → 10 MP, 50 XP, Streak 1.
 * Quests + Rewards identisch zu `familyWithQuestAndReward`.
 */
export function seedChildWithApprovedQuest(): SeedPayload {
  const base = seedFamilyWithQuestAndReward();
  const today = nowIso();
  const hero = buildHero(IDS.childLucaId, 'Luca', {
    level: 1,
    currentXP: 50,
    currentStreak: 1,
    longestStreak: 1,
    activityDates: [today],
    lastActiveDate: today,
  });
  return {
    ...base,
    heroes: [hero],
    pointsAccounts: [buildPointsAccount(IDS.childLucaId, 10)],
    transactions: [
      {
        id: 'txn-seed-001',
        userId: IDS.childLucaId,
        type: 'questComplete',
        amount: 10,
        balanceAfter: 10,
        referenceId: IDS.questCleanRoomId,
        description: 'Quest abgeschlossen: Zimmer aufräumen',
        createdAt: today,
      },
    ],
    questInstances: [
      {
        id: 'qi-seed-001',
        questId: IDS.questCleanRoomId,
        childId: IDS.childLucaId,
        status: 'completed',
        progress: 1,
        target: 1,
        currentStreak: 0,
        startedAt: today,
        completedAt: today,
        approvedAt: today,
        approvedBy: IDS.parentMamaId,
        createdAt: today,
      },
    ],
  };
}
