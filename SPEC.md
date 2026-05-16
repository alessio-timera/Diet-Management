# The Weekly Plate — Project Spec

> A personal nutrition planning & tracking app for muscle building, with an integrated AI chef assistant. Built as a static, dependency-free web app — designed for progressive improvement.

---

## Table of Contents

1. [Vision & Philosophy](#1-vision--philosophy)
2. [Current Features (MVP — already built)](#2-current-features-mvp--already-built)
3. [Tech Stack & Constraints](#3-tech-stack--constraints)
4. [User Profile (Defaults)](#4-user-profile-defaults)
5. [Macronutrient Calculation Logic](#5-macronutrient-calculation-logic)
6. [Repository Structure](#6-repository-structure)
7. [Data Models](#7-data-models)
8. [Module-by-Module Specification](#8-module-by-module-specification)
9. [Storage Layer](#9-storage-layer)
10. [AI Assistant Integration](#10-ai-assistant-integration)
11. [Design System](#11-design-system)
12. [Roadmap](#12-roadmap)
13. [Setup Instructions](#13-setup-instructions)
14. [Baseline HTML — the current artifact (v3)](#14-baseline-html--the-current-artifact-v3)

---

## 1. Vision & Philosophy

**The Weekly Plate** is a personal kitchen wiki + meal planner. You select dishes for each day of the week, the app generates a consolidated shopping list, tracks your daily macronutrients, and gives you access to a chat-based AI chef that knows your profile and can suggest new recipes that get added to your library.

**Core principles:**

- **Single-file simplicity.** No build step, no frameworks. Just HTML/CSS/JS that runs anywhere.
- **Progressive enhancement.** Each feature is additive. The app works even if half the modules fail.
- **Editorial design.** Looks like an old food magazine, not a SaaS dashboard. Distinctive, warm, paper-textured.
- **Single-user, local-first.** All data lives in the browser. No accounts, no servers (except the Claude API for the chat).
- **Your library, not the app's library.** The recipe book grows over time with AI-suggested dishes you approve.

**Non-goals (for now):**

- Training plans, body-weight tracking, sleep tracking — explicitly out of scope for v1.
- Multi-user, sharing, social features.
- Mobile-native apps. (The web app is mobile-friendly; that's enough.)

---

## 2. Current Features (MVP — already built)

These are all in the baseline HTML at [§14](#14-baseline-html--the-current-artifact-v3). The new repo should preserve every feature.

### 2.1 — Planner Tab

- 7-day week (Monday–Sunday), 3 meals per day (breakfast / lunch / dinner).
- For each meal, the user selects:
  - **Who it's for** — "Me only" or "Both" (Me + pescatarian girlfriend).
  - **Which dish** — dropdown filtered by meal type and dietary constraint.
  - Or marks the meal as "Skip (eating out)".
- "View recipe →" link opens a modal with full ingredients + step-by-step method.
- **Daily macro totals** under each day card: kcal / protein / carbs / fat as labeled progress bars against daily targets. Bars turn plum when >105% of target. Macros always reflect *the user's* serving (girlfriend's portion not added to user's daily totals, even on shared meals).
- **Controls**: Reset Week, Surprise Me (randomized week), Print Plan.

### 2.2 — Auto-Shopping List

- Aggregates ingredients across all selected meals.
- Shared meals (whom = "both") count ingredients **2×**.
- Quantities sum across dishes (e.g. chicken used in 3 dishes shows the total).
- Groups by category: Protein / Produce / Dairy & Eggs / Pantry / Bakery / Frozen.
- Auto-converts: 1000g → 1kg, 1000ml → 1l.

### 2.3 — Recipe Book Tab

- Browse all recipes (built-in + AI-added) as cards.
- Filters: All / Breakfasts / Lunches / Dinners / Pescatarian / From AI.
- Each card shows: name, type, pescatarian flag, kcal, protein, carbs, fat, cook time.
- Click any card to open the full recipe modal.
- AI-added recipes can be deleted; built-in cannot.

### 2.4 — Chef Assistant Tab

- Free chat with Claude (via the Anthropic API).
- System prompt embeds the user's profile (weight, goal, macros, cuisines, girlfriend's pescatarian diet, etc.).
- When the assistant suggests a recipe, it formats it in a ` ```recipe ` JSON block.
- The app parses the block, shows a "+ Add to recipe book" button, and on click the recipe joins the library and becomes selectable in the planner.
- Chat history persists.

### 2.5 — Persistence

Three things saved to local storage:
- **Week plan** — what dish is selected for each meal, for whom.
- **AI-added recipes** — recipes the user has accepted.
- **Chat history** — full conversation with the chef.

Built-in recipes are not stored; they live in the code so they're always fresh.

---

## 3. Tech Stack & Constraints

**Stack:**
- HTML, CSS, vanilla JavaScript (ES2020+).
- No frameworks, no build step, no npm install.
- Google Fonts (Fraunces + JetBrains Mono) loaded from CDN.
- Anthropic Claude API for the chef assistant.

**Hosting:**
- Static site. GitHub Pages, Netlify, Vercel, Cloudflare Pages — anything works.
- Recommended: **GitHub Pages** for simplicity (push to `main`, enable Pages, done).

**Why this stack:**
- Zero dependencies = zero supply-chain risk and zero `npm audit` rabbit holes.
- No build means no toolchain to maintain. Edit a file, refresh the page, done.
- Easy for the user (a beginner) to iterate on solo.
- Migrating to a framework later is straightforward if the data layer is clean.

**Critical constraint — API key handling:**

The current artifact uses Anthropic's hosted API directly from the browser (the artifact environment auto-injects credentials). **In a real repo this won't work**: you can't put your API key in client-side code without exposing it. You have three options:

1. **Server proxy (recommended).** Add a tiny serverless function that takes the user's chat message, calls Claude with the API key kept secret on the server, and returns the response. Cloudflare Workers, Vercel Functions, or Netlify Functions all work. This is ~30 lines of code.
2. **Local-only mode.** The user enters their own API key in a settings panel; it's stored in localStorage and used directly from the browser. Acceptable for a personal app but the key is exposed to anyone with browser access.
3. **Disable the chat feature** entirely until the proxy is built.

The spec assumes **option 1**. A `/api/chat` endpoint is implied throughout; see [§10.3](#103-api-proxy-implementation).

---

## 4. User Profile (Defaults)

These are hardcoded in the app today. Eventually they should be editable in a Settings panel (see [Roadmap](#12-roadmap)).

```js
const USER_PROFILE = {
  weight_kg: 80,
  age: 30,
  sex: "male",
  height_cm: 178,           // assumed — verify and update
  goal: "muscle gain",
  activity: "light",        // sedentary | light | moderate | high
  training_per_week: 3,
  cook_time_target_min: "15-25",
  cuisines_preferred: ["Mediterranean", "Asian", "Tex-Mex", "Classic American"],
  proteins_preferred: ["chicken", "eggs", "yogurt", "cottage cheese", "tuna", "salmon", "beef", "turkey", "legumes"],
  dietary_restrictions: [],
  units: "metric"
};

const PARTNER_PROFILE = {
  enabled: true,
  diet: "lacto-ovo-pescatarian",  // eats fish, eggs, dairy; no meat
  share_portion: "same"            // same as user's serving
};
```

---

## 5. Macronutrient Calculation Logic

These numbers are not magic — they're derived from standard sports-nutrition equations. **Document them in code so they can be recomputed if the profile changes.**

### 5.1 — BMR (Basal Metabolic Rate)

Use **Mifflin-St Jeor**, the most accurate equation for the general population:

```
For men:   BMR = 10×weight_kg + 6.25×height_cm − 5×age + 5
For women: BMR = 10×weight_kg + 6.25×height_cm − 5×age − 161
```

For the default profile (80kg, 178cm, 30yo, male): BMR ≈ **1,918 kcal/day**.

### 5.2 — TDEE (Total Daily Energy Expenditure)

`TDEE = BMR × activity_factor`

| activity | factor | description |
|---|---|---|
| sedentary | 1.2 | desk job, no exercise |
| light | 1.375 | 1-3 workouts/week |
| moderate | 1.55 | 3-5 workouts/week |
| high | 1.725 | 6+ workouts/week or physical job |

For default (light): TDEE ≈ **1,918 × 1.375 = 2,640 kcal/day** (maintenance).

### 5.3 — Calorie Target

| goal | adjustment |
|---|---|
| fat loss | TDEE − 400 to −500 |
| maintenance | TDEE |
| muscle gain | TDEE + 200 to +400 |
| aggressive bulk | TDEE + 500 |

For muscle gain at light activity: **~2,800 kcal/day**. The current artifact uses 2,700 as a conservative starting point — this should be derivable from the profile, not hardcoded.

### 5.4 — Protein

Research-backed range for muscle building: **1.6 to 2.2 g per kg bodyweight per day**.

Default target: `weight_kg × 1.8` → 80 × 1.8 = **144g**. Current artifact uses 150g.

### 5.5 — Carbs & Fat

After fixing kcal and protein, the rest is split:
- Reserve at least `weight_kg × 0.7` g of fat (~55g for an 80kg person) for hormone health.
- Remaining calories go to carbs.

Split roughly **60% carbs / 40% fat** of the remainder (or 50/50 for lower-volume training). For the default profile this gives ~300g C and ~80g F.

### 5.6 — Implementation

These calculations should live in `js/macros.js`:

```js
export function computeTargets(profile) {
  const bmr = profile.sex === "male"
    ? 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * profile.age + 5
    : 10 * profile.weight_kg + 6.25 * profile.height_cm - 5 * profile.age - 161;

  const activityFactors = { sedentary: 1.2, light: 1.375, moderate: 1.55, high: 1.725 };
  const tdee = bmr * activityFactors[profile.activity];

  const goalAdjustments = { fat_loss: -450, maintenance: 0, muscle_gain: 300, bulk: 500 };
  const kcal = Math.round(tdee + goalAdjustments[profile.goal]);

  const protein = Math.round(profile.weight_kg * 1.8);
  const minFat = Math.round(profile.weight_kg * 0.7);

  const proteinKcal = protein * 4;
  const remainingKcal = kcal - proteinKcal;
  const fatKcal = remainingKcal * 0.35;
  const carbKcal = remainingKcal * 0.65;

  return {
    kcal,
    protein,
    carbs: Math.round(carbKcal / 4),
    fat: Math.max(minFat, Math.round(fatKcal / 9))
  };
}
```

This replaces the hardcoded `TARGETS` constant in the current artifact.

---

## 6. Repository Structure

```
weekly-plate/
├── index.html                  # Entry point, mostly markup
├── api/
│   └── chat.js                 # Serverless proxy for Claude API (Cloudflare Worker / Vercel Function)
├── js/
│   ├── app.js                  # Bootstrap: load data, init tabs, render
│   ├── state.js                # Central state object + load/save
│   ├── storage.js              # localStorage wrapper
│   ├── profile.js              # USER_PROFILE, PARTNER_PROFILE
│   ├── macros.js               # computeTargets() — see §5.6
│   ├── modules/
│   │   ├── planner.js          # Renders day cards, handles meal selection
│   │   ├── shopping.js         # Computes & renders the shopping list
│   │   ├── recipes.js          # Recipe book tab
│   │   ├── chef.js             # AI chat tab
│   │   └── modal.js            # Recipe modal
│   └── data/
│       ├── built-in-recipes.js # The 22 starter recipes
│       └── recipe-schema.js    # JSON schema + validator for recipes
├── css/
│   ├── tokens.css              # Design tokens (colors, fonts) — CSS custom properties
│   ├── base.css                # Reset, typography, layout
│   └── components.css          # Component styles (cards, modals, tabs, etc.)
├── README.md                   # Setup instructions, screenshots, link to live demo
├── SPEC.md                     # This file
└── .gitignore
```

**Why this structure:**
- ES modules (`import`/`export`) so each file has clear inputs/outputs.
- Data separated from logic separated from presentation.
- Adding a new recipe = editing one file (`built-in-recipes.js`).
- Adding a new tab = adding a new `modules/*.js` file and one section to `index.html`.

**Migration from the artifact:**
The baseline HTML in [§14](#14-baseline-html--the-current-artifact-v3) is one giant file. The repo should split it as follows:
- All `<style>` content → `css/base.css` + `css/components.css` (split by responsibility), with the `:root` variables moved to `css/tokens.css`.
- All `<script>` content → split by feature into `js/modules/*.js`, with shared state in `js/state.js`.
- The `BUILT_IN_DISHES` object → `js/data/built-in-recipes.js`.
- The `SYSTEM_PROMPT` constant → `js/modules/chef.js` (or its own `prompts.js` file if it grows).

---

## 7. Data Models

### 7.1 — Recipe

```js
{
  id: "d_chicken_potatoes",           // unique slug
  name: "Roast chicken thighs & potatoes",
  type: "breakfast" | "lunch" | "dinner",
  time: "35 min",                      // human-readable
  kcal: 740,
  protein: 50,                          // grams
  carbs: 65,                            // grams
  fat: 28,                              // grams
  pescatarian: false,                   // true = no meat/poultry
  source: "built-in" | "ai",
  ingredients: [
    {
      item: "Chicken thighs (boneless, skinless)",
      qty: 220,
      unit: "g",                        // g | kg | ml | l | pc | slices | cloves | tbsp | tsp
      cat: "Protein"                    // Protein | Produce | Dairy & Eggs | Pantry | Bakery | Frozen
    },
    // ...
  ],
  steps: [
    "Heat oven to 220°C (425°F).",
    "Cut potatoes into 2cm chunks. Toss with oil, salt, smashed garlic on a tray.",
    // ...
  ],
  tags: []                              // future: ["batch-cook", "training-day", "cheap", ...]
}
```

The current artifact has 22 built-in recipes (5 breakfasts, 7 lunches, 10 dinners — 5 meat dinners, 5 pescatarian dinners). All of them are in the baseline HTML in [§14](#14-baseline-html--the-current-artifact-v3).

### 7.2 — Week Plan State

```js
{
  Monday: {
    breakfast: { dish: "b_oats_yogurt" | "skip" | "",  whom: "me" | "both" },
    lunch:     { dish: "...", whom: "..." },
    dinner:    { dish: "...", whom: "..." }
  },
  Tuesday: { ... },
  // ...Sunday
}
```

### 7.3 — Chat Message

```js
{
  role: "user" | "assistant",
  content: "string with possible ```recipe ...``` blocks"
}
```

---

## 8. Module-by-Module Specification

### 8.1 — `js/app.js`

Entry point. On `DOMContentLoaded`:
1. Calls `storage.loadAll()` to hydrate state from localStorage.
2. Computes targets via `macros.computeTargets(USER_PROFILE)`.
3. Initializes tab navigation.
4. Renders the initial planner view, shopping list, chat.

### 8.2 — `js/state.js`

Exports a single mutable state object. Other modules subscribe to changes by re-rendering after they call mutating functions. Keep it simple — no Redux, no observables. Just:

```js
export const state = {
  profile: USER_PROFILE,
  targets: null,           // populated by macros.computeTargets()
  week: {},                // see §7.2
  recipes: {},             // merged built-in + AI
  chat: [],                // see §7.3
};

export function setMeal(day, mealType, dish, whom) {
  state.week[day][mealType] = { dish, whom };
  storage.saveWeek(state.week);
}
// ... etc.
```

### 8.3 — `js/storage.js`

Thin wrapper around `localStorage`. Three keys:

```js
const KEYS = {
  week:    "weekly-plate:week",
  recipes: "weekly-plate:ai-recipes",
  chat:    "weekly-plate:chat"
};

export function load(key)     { try { return JSON.parse(localStorage.getItem(KEYS[key])); } catch { return null; } }
export function save(key, v)  { localStorage.setItem(KEYS[key], JSON.stringify(v)); }
export function loadAll()     { /* hydrate state.week, state.recipes, state.chat */ }
```

**Migration note:** the artifact uses `window.storage.get/set` (Claude artifact API). When porting to the repo, replace with the above. The data shape is identical.

### 8.4 — `js/modules/planner.js`

Renders the 7 day cards. For each meal slot:
- "Me / Both" toggle. Switching to "Both" clears non-pescatarian dishes from that slot with a toast.
- Dish dropdown, filtered by meal type AND (whom === "both" ? pescatarian only : all).
- Recipe link button (calls `modal.open(dishId)`).
- Daily macro bars at the bottom of each day card.

After any change, re-render only the affected day + the shopping list + the macro bars. Don't re-render the whole planner.

### 8.5 — `js/modules/shopping.js`

`renderShopping(state)`:
1. Walk every meal in the week.
2. For each non-skip dish, multiply ingredient quantities by `whom === "both" ? 2 : 1`.
3. Aggregate by `(category, item, unit)`.
4. Group by category, sort alphabetically within each.
5. Render with `formatQuantity()` (handles g→kg, ml→l, piece pluralization).

### 8.6 — `js/modules/recipes.js`

The Recipe Book tab. Filterable grid of cards. Filters: All / Breakfasts / Lunches / Dinners / Pescatarian / From AI. Clicking a card opens the modal.

### 8.7 — `js/modules/chef.js`

The AI chat tab.

On send:
1. Append user message to `state.chat`.
2. POST to `/api/chat` with the full history + system prompt.
3. Receive assistant text. Parse any ` ```recipe ` blocks via the recipe schema validator.
4. Append assistant message. Render with "+ Add to recipe book" button next to each parsed recipe.

The system prompt should live in this file as a const string. It must include:
- The full user profile (weight, age, goal, training, macro targets).
- The partner's pescatarian status (lacto-ovo).
- The recipe JSON format spec.
- Sizing rules (lunch/dinner: 600-750 kcal & 45-55g protein; breakfast: 450-560 kcal & 30-40g protein).

The current artifact's system prompt is reproduced verbatim in [§14](#14-baseline-html--the-current-artifact-v3) — use it as-is.

### 8.8 — `js/modules/modal.js`

Generic modal. Used by both the recipe view and any future modals (settings, etc.). Open/close, ESC handler, click-outside handler.

### 8.9 — `js/data/built-in-recipes.js`

A single `export const BUILT_IN_RECIPES = { ... }` with all 22 recipes. Copy the entire `BUILT_IN_DISHES` object from the baseline HTML — it's already in the right shape.

### 8.10 — `js/data/recipe-schema.js`

A validator function for AI-suggested recipes:

```js
export function validateRecipe(r) {
  const errors = [];
  if (!r.name) errors.push("missing name");
  if (!["breakfast", "lunch", "dinner"].includes(r.type)) errors.push("invalid type");
  if (typeof r.kcal !== "number") errors.push("kcal must be a number");
  // ...
  return { valid: errors.length === 0, errors };
}
```

This guards against malformed JSON from the AI.

---

## 9. Storage Layer

All persistence is `localStorage`. No IndexedDB needed at this scale (we're at ~50KB tops even with extensive AI recipes).

**Quota:** browsers give 5-10MB of localStorage per origin. We're nowhere near.

**Backup/restore:** add an export button that downloads a JSON file with all three storage keys, and an import button that loads it. This is critical for a single-user app — there's no other safety net. Treat it as a v1 feature.

```js
function exportData() {
  const blob = new Blob([JSON.stringify({
    week: state.week,
    recipes: getAIRecipes(state.recipes),
    chat: state.chat,
    exported_at: new Date().toISOString()
  }, null, 2)], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = `weekly-plate-${new Date().toISOString().split('T')[0]}.json`;
  a.click();
}
```

---

## 10. AI Assistant Integration

### 10.1 — Model

Use Claude Sonnet 4 (or Haiku 4.5 if cost is a concern — it'll be faster and cheaper, with slightly less nuanced recipe creativity). The model string is `claude-sonnet-4-5` or whatever's current — check the Anthropic docs for the latest.

### 10.2 — Recipe JSON Format

The system prompt enforces this exact shape:

```recipe
{
  "name": "Dish name",
  "type": "lunch",
  "time": "20 min",
  "kcal": 700,
  "protein": 50,
  "carbs": 70,
  "fat": 22,
  "pescatarian": true,
  "ingredients": [
    {"item": "Salmon fillet", "qty": 180, "unit": "g", "cat": "Protein"}
  ],
  "steps": ["Step one.", "Step two."]
}
```

Important guardrails in the prompt:
- `pescatarian: true` if no meat/poultry; false if it contains meat.
- Macros must roughly add up: `protein×4 + carbs×4 + fat×9 ≈ kcal`.
- Sized for 1 serving matching the profile (lunch/dinner: 600-750 kcal; breakfast: 450-560 kcal).

### 10.3 — API Proxy Implementation

Example Cloudflare Worker (`api/chat.js`):

```js
export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const { messages, system } = await request.json();

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01"
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-5",
        max_tokens: 1500,
        system,
        messages
      })
    });

    return new Response(await response.text(), {
      headers: { "Content-Type": "application/json" }
    });
  }
};
```

In `chef.js`, change the fetch URL from `https://api.anthropic.com/v1/messages` to `/api/chat`, and remove the `system` from being passed by client (let the server inject it for stronger guardrails) — or pass it from client if you want flexibility. Tradeoff: server-injected system prompt is harder to tamper with; client-side allows easier iteration during development.

### 10.4 — Cost Budgeting

A typical chat round with the chef costs ~$0.01-0.03 in API spend. For personal use this is trivial. For peace of mind:
- Add a daily request limit in the proxy (e.g. 50 messages/day).
- Or use a free-tier API key with rate limits.

---

## 11. Design System

The current aesthetic is **editorial food magazine**: warm paper background with subtle noise texture, double-line rules, kraft-paper palette, large italic display headers in Fraunces. **Do not lose this** when porting. It's what makes the app feel like a personal artifact and not a generic SaaS dashboard.

### 11.1 — Tokens (`css/tokens.css`)

```css
:root {
  --paper:    #f3ead8;
  --paper-2:  #ece1c9;
  --ink:      #1d1a14;
  --ink-soft: #4a4234;
  --accent:   #b4391a;  /* warm red — primary accent */
  --accent-2: #1f5d3a;  /* deep green — secondary, used for pescatarian/AI tags */
  --gold:     #b88a2c;  /* gold — used for carbs bar */
  --plum:     #6b2740;  /* plum — used for "shared" / "over target" */
}
```

### 11.2 — Type

- Display: **Fraunces** (italic, weights 700-900). Used for h1, h2, h3, card titles.
- UI: **JetBrains Mono** (400, 600). Used for kickers, labels, stamps, all-caps small text.
- Body: **Fraunces** regular.

### 11.3 — Layout patterns

- Double-line rules (`border-top: 6px double var(--ink)`) for masthead and footer.
- 2px solid borders on most cards.
- "Stamp" effect for tags: rotated -2deg, bordered, monospace.
- Hover lift on recipe cards (`transform: translate(-2px, -2px); box-shadow: 4px 4px 0 var(--ink);`).
- Bars on macro indicators: 6px tall, 1px border, fill width = `min(100%, val/target*100%)`.

### 11.4 — Color usage rules

- `--ink` for primary text, primary buttons, calorie bar.
- `--accent` for kickers, protein bar, "meat" indicator.
- `--accent-2` for "pescatarian", AI badge, fat bar.
- `--gold` for carbs bar.
- `--plum` for "shared" / "over target" states.

---

## 12. Roadmap

In rough priority order. Don't build everything before launching — ship v1 with current features and iterate.

### Phase 1 — Foundation (the current spec)
- [x] Planner with meal/whom selection
- [x] Auto-shopping list
- [x] Recipe book
- [x] AI chef assistant
- [x] Local persistence
- [ ] Move from artifact to repo (this spec)
- [ ] Settings panel for the profile (edit weight, height, goal, etc., recompute targets)
- [ ] Export/import JSON backup

### Phase 2 — Smarter nutrition
- [ ] Body-weight tracking (weekly weigh-in chart; auto-adjust kcal target if weight isn't moving as expected)
- [ ] Weekly macro summary view (averages, training-day vs rest-day split)
- [ ] Tag system on recipes (`training-day`, `batch-cook`, `cheap`, `summer`...)
- [ ] Pantry mode: "I have these ingredients, what can I cook?"
- [ ] Recipe scaling (cook 2-3 servings for leftovers)
- [ ] Shopping list export (copy as text, send to email/Notes)

### Phase 3 — Training & health
- [ ] 3-day/week training plan generator (push/pull/legs or upper/lower/full)
- [ ] Exercise library with form notes & video links
- [ ] Set/rep/weight tracking with progressive overload
- [ ] Linking training days to higher-carb meals automatically
- [ ] Sleep, energy, soreness check-ins
- [ ] Unified weekly dashboard

### Phase 4 — Polish
- [ ] PWA: installable on phone, works offline
- [ ] Onboarding flow for new users
- [ ] Theme toggle (paper / dark mode)
- [ ] Print stylesheet that produces a beautiful weekly menu card

---

## 13. Setup Instructions

For the README, in plain steps a beginner can follow:

```bash
# 1. Clone
git clone https://github.com/<you>/weekly-plate.git
cd weekly-plate

# 2. Serve locally (no build needed — pick one)
#    Python:
python3 -m http.server 8000
#    or Node:
npx serve

# 3. Open http://localhost:8000

# 4. Deploy to GitHub Pages
#    - Push to `main`
#    - Repo Settings → Pages → Source: main / root
#    - Visit https://<you>.github.io/weekly-plate

# 5. Set up the API proxy (for the chat tab)
#    - Sign up at cloudflare.com (free tier)
#    - Install wrangler: npm install -g wrangler
#    - cd api && wrangler init
#    - Copy api/chat.js into the worker
#    - wrangler secret put ANTHROPIC_API_KEY  (paste your key)
#    - wrangler deploy
#    - Update the fetch URL in js/modules/chef.js to your worker URL
```

---

## 14. Baseline HTML — the current artifact (v3)

This is the working app today. Save it as `index.html` in the new repo as a starting point, then split it into the structure described in [§6](#6-repository-structure). All future work is refactoring this into modules without changing user-visible behavior.

```html
<!-- See companion file: index.html (baseline) -->
```

> **Note:** the full HTML is ~75KB and is shipped as a separate file (`index.html`) alongside this spec, since embedding it inline would make this document unwieldy. Copy that file into the root of the new repo and start splitting it according to [§6](#6-repository-structure).

---

## Appendix A — Notes on Macro Numbers

The targets are derivable, not fixed. If you ever change weight, training frequency, or goal, the app should recompute. Some honest caveats from the science:

- **The protein target (1.6-2.2g/kg) is well-evidenced.** Hit it. There's no real benefit going much higher.
- **The calorie target is an estimate.** The only true test is tracking your bodyweight over 2-3 weeks. If you're not gaining ~0.25-0.5 kg/month on muscle gain, add 200 kcal. If you're gaining more than 0.7 kg/month, you're probably gaining fat — cut 200.
- **The carb/fat split barely matters** as long as fat stays above ~0.7 g/kg for hormone health. Don't optimize this until the basics are dialed in.
- **Training matters more than nutrition margins.** A great training program + decent nutrition beats perfect nutrition + mediocre training every time. Once the training plan feature exists, this app should help correlate the two.

---

## Appendix B — Why the AI sometimes returns invalid recipes

The AI assistant returns JSON in ` ```recipe ` blocks. Despite the system prompt being strict, occasional issues happen:

- **Trailing commas** in JSON (invalid by spec, but the AI sometimes adds them). Solution: try `JSON.parse` first; if it fails, strip trailing commas and retry.
- **Wrong field types** (e.g. `"180"` instead of `180`). Solution: coerce numbers in the validator.
- **Missing optional fields** like `tags`. Solution: default them in the validator.
- **Wrong category name** ("Meat" instead of "Protein"). Solution: map common variants to the canonical names in the validator.

Build the validator (`js/data/recipe-schema.js`) defensively. The user shouldn't see an error when the AI hiccups — the validator should heal what it can.

---

*End of spec.*
