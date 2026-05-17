# The Weekly Plate — CLAUDE.md

Context file for AI-assisted development. Read this at the start of every new session.

---

## What this project is

A personal weekly meal planner built as a single `index.html` with no build step, no frameworks, and no backend. Hosted on GitHub Pages at `https://alessio-timera.github.io/Diet-Management/`. Installable as a PWA on phone.

**Users:** Ale (muscle gain, no dietary restriction) and Nastya (pescatarian).

**Core features:**
- 7-day planner: pick breakfast, lunch, dinner per day
- Per-meal person toggle: Ale / Nastya / Both (pescatarian filter applies when Nastya or Both)
- Lunch and dinner menus are interchangeable — both slots share the same recipe pool
- Collapsible day cards (all start collapsed)
- Dual macro bars per day: one row per person vs their own targets; each row toggleable
- Total prep time per day (sum of dish times, person-agnostic)
- Stats bar at top of Planner: two rows (Ale + Nastya), each collapsible by clicking the name; Nastya hidden by default
- Shopping list tab: ingredients aggregated across all selected meals, 2× when shared
- Recipe book with filters
- Settings: separate full profiles for Ale and Nastya (Mifflin-St Jeor)
- Export / Import JSON backup
- PWA installable from phone browser

---

## Architecture

```
index.html          Single file — all HTML, CSS, JS (~1850 lines)
recipes/
  index.json        Manifest of recipe IDs — update manually or run serve.ps1
  _template.json    Copy-paste template for new recipes
  *.json            One file per recipe (36 total)
manifest.json       PWA manifest
icons/icon.svg      App icon
serve.ps1           Local dev server script (run via Ctrl+Shift+B in VSCode)
.vscode/tasks.json  VSCode task: runs serve.ps1
README.md           User-facing docs
SPEC.md             Original spec (for reference)
```

**Run locally:** Ctrl+Shift+B in VSCode (or `powershell -File serve.ps1`). Opens `http://localhost:8000` automatically. `serve.ps1` also regenerates `recipes/index.json` from disk on every run.

**Deploy:** push to `main` → GitHub Pages auto-deploys within ~1 minute.

---

## Key JS architecture

### Globals
```js
// Profiles
let userProfile  = { weight_kg, height_cm, age, sex, goal, activity }  // Ale
let userProfileA = { weight_kg, height_cm, age, sex, goal, activity }  // Nastya
let TARGETS  = computeTargets(userProfile)   // { kcal, protein, carbs, fat }
let TARGETS_A = computeTargets(userProfileA)

// Defaults
DEFAULT_PROFILE   = { weight_kg:78, height_cm:180, age:30, sex:"male",   goal:"muscle_gain", activity:"light" }
DEFAULT_PROFILE_A = { weight_kg:59, height_cm:173, age:28, sex:"female", goal:"maintenance",  activity:"light" }

// Recipes
let DISHES = {}           // id -> recipe object (built-in + AI-added)
let BUILT_IN_IDS = new Set()  // set of built-in recipe IDs

// Week plan
let state = {
  Monday: { breakfast: { dish: "recipe_id_or_skip_or_empty", whom: "alessio"|"anastasiia"|"both" }, lunch: ..., dinner: ... },
  ...
}
```

### Storage keys (localStorage)
```js
STORAGE_KEYS = {
  state:    "weekly-plate:week",
  recipes:  "weekly-plate:ai-recipes",
  profile:  "weekly-plate:profile",
  profileA: "weekly-plate:profile-anastasiia"
}
```

### Whom values (internal identifiers — do NOT rename, they are stored in localStorage)
- `"alessio"` — only Ale eats; any dish allowed
- `"anastasiia"` — only Nastya eats; pescatarian filter applies
- `"both"` — both eat; pescatarian filter applies; shopping quantity ×2

### Key functions
| Function | What it does |
|---|---|
| `computeTargets(profile)` | Mifflin-St Jeor → `{ kcal, protein, carbs, fat }` |
| `loadRecipes()` | async; fetches `recipes/index.json` then each `recipes/{id}.json` |
| `loadAll()` | Restores profiles, state, AI recipes from localStorage; migrates old `whom:"me"` → `"alessio"` |
| `buildDays()` | Renders all 7 day cards (collapsed by default); attaches expand/collapse click handler |
| `renderMealsForDay(day)` | Re-renders meals inside a day card (dropdowns, whom toggle, recipe link) |
| `renderDayMacros(day)` | Renders per-person macro bars + prep time for a day |
| `getDishesByType(whom)` | Returns `{ breakfast:[], lunch:[], dinner:[] }` — lunch and dinner share the same pool |
| `renderShopping()` | Aggregates all ingredients across the week; called on Shopping tab visit |
| `renderRecipeBook()` | Called when Recipe Book tab is opened |
| `populateSettings()` | Fills both profile forms; called when Settings tab is opened |
| `renderComputedTargets()` | Live preview of Ale's computed targets while editing |
| `renderComputedTargetsA()` | Same for Nastya |
| `parseMinutes(timeStr)` | Extracts first integer from strings like "25 min", "35 min (mostly oven)" |
| `formatQty(qty, unit)` | Converts g→kg, ml→l at 1000; formats display string |
| `showToast(msg)` | 1.8s toast notification |
| `updateStatsDisplay()` | Updates both Ale's and Nastya's rows in the top stats bar |

### Macro bar logic (`renderDayMacros`)
- Iterates all MEAL_TYPES for the day
- If `whom === "alessio"` or `"both"` → adds to Ale's totals
- If `whom === "anastasiia"` or `"both"` → adds to Nastya's totals
- Each `.day-macros-person` div has `data-person="ale"` or `data-person="nastya"`
- Shows prep time (sum of `parseMinutes(dish.time)` for all non-empty, non-skip meals)
- Hides a person's block entirely if they have 0 meals that day OR if the body class hides them

### Stats bar visibility toggle
The top stats bar uses two `.stats-row` wrappers (`.stats-row-ale`, `.stats-row-nastya`).
Clicking the person name cell toggles a CSS class on `<body>`:
```
body.hide-ale-targets     → collapses Ale's stats row + hides [data-person="ale"] macro bars
body.hide-nastya-targets  → collapses Nastya's stats row + hides [data-person="nastya"] macro bars
```
`body.hide-nastya-targets` is added on page load (Nastya hidden by default).
Name cell shows `▾` when expanded, `▸` when collapsed.

### Lunch / dinner interchangeability
`getDishesByType(whom)` puts every recipe with `type === "lunch"` or `type === "dinner"` into **both** the `lunch` and `dinner` buckets. Breakfast remains separate. This means all 31 lunch+dinner recipes appear in both meal slots.

---

## Tab structure

```
01 Planner | 02 Shopping | 03 Recipe Book | 04 Settings | 05 Chef
```
- Panel IDs: `panel-planner`, `panel-shopping`, `panel-recipes`, `panel-settings`, `panel-assistant`
- Tab switching: `document.querySelectorAll(".tab")` click handler activates the panel

---

## Recipe JSON schema

```json
{
  "id": "d_my_recipe",
  "name": "My Recipe Name",
  "type": "dinner",
  "time": "25 min",
  "kcal": 700,
  "protein": 48,
  "carbs": 70,
  "fat": 22,
  "pescatarian": false,
  "source": "built-in",
  "ingredients": [
    { "item": "Chicken breast", "qty": 200, "unit": "g",   "cat": "Protein" },
    { "item": "Olive oil",      "qty": 15,  "unit": "ml",  "cat": "Pantry"  }
  ],
  "steps": ["Step one.", "Step two."],
  "tags": []
}
```

**Valid units:** `g`, `kg`, `ml`, `l`, `pc`, `slices`, `cloves`, `tbsp`, `tsp`
**Valid categories:** `Protein`, `Produce`, `Dairy & Eggs`, `Pantry`, `Bakery`, `Frozen`
**Valid types:** `breakfast`, `lunch`, `dinner`
**pescatarian:** `true` if no meat/poultry (fish, eggs, dairy, legumes OK)

To add a recipe: create `recipes/{id}.json`, add the ID to `recipes/index.json` in alphabetical order, then push to GitHub. Running serve.ps1 also regenerates `index.json` automatically.

---

## Current recipes (36 total)

**Breakfasts (5):** b_cottage_toast, b_eggs_toast, b_oats_yogurt, b_omelet_oats, b_overnight_oats

**Lunches (9):** l_beef_burrito_bowl, l_chicken_rice, l_chicken_wrap, l_crostino_burrata, l_egg_fried_rice, l_lentil_soup, l_minestrone, l_salmon_couscous, l_tuna_pasta

**Dinners (22):** d_beef_stir_fry, d_butter_bean_cassoulet, d_chicken_potatoes, d_chicken_souvlaki, d_chickpea_curry, d_cod_veg, d_curried_chickpea_carrot, d_harissa_chickpea_quinoa, d_harissa_trout, d_lentil_chicken, d_mushroom_beanotto, d_parmigiana_eggplant, d_pork_sweet_sour, d_risotto_milanese, d_salmon_hoisin, d_salmon_quinoa, d_shrimp_pasta, d_truffle_tagliatelle, d_tuna_potato_salad, d_turkey_meatballs, d_turkey_ragu_gnocchi, d_white_bean_steak

*Note: because lunch/dinner are interchangeable, all 31 lunch+dinner recipes appear in both meal slots.*

---

## CSS design tokens

```css
--paper:    #f3ead8   /* warm parchment background */
--paper-2:  #ece1c9   /* slightly darker parchment */
--ink:      #1d1a14   /* near-black text */
--ink-soft: #4a4234   /* muted text */
--accent:   #b4391a   /* terracotta red */
--accent-2: #1f5d3a   /* forest green */
--gold:     #b88a2c   /* warm gold */
--plum:     #6b2740   /* deep plum */
```

Fonts: `Fraunces` (serif body/headings), `JetBrains Mono` (labels, tags, monospace).

**Whom-button active colors:**
- Ale active → `var(--ink)` (dark)
- Nastya active → `var(--accent-2)` (green)
- Both active → `var(--plum)` (plum)

**Stats row name colors:**
- `.ale-name` → `var(--ink)`
- `.nastya-name` → `var(--accent-2)`

---

## Important implementation notes

1. **serve.ps1 must use ASCII only** — PowerShell 5.1 without UTF-8 BOM misinterprets Unicode characters. No em-dashes, box-drawing chars, curly quotes in serve.ps1.

2. **Internal whom identifiers are `"alessio"` and `"anastasiia"`** — display names in the UI are "Ale" and "Nastya" but the internal JS/localStorage values must stay as `"alessio"` / `"anastasiia"` for backward compatibility with saved state. Never rename these strings in code.

3. **state migration** — `loadAll()` migrates old `whom:"me"` → `"alessio"` automatically for backward compat with saved state.

4. **index.json** — `serve.ps1` regenerates it from all `.json` files in `/recipes/` on every run. The `_template.json` is excluded from the scan. When adding a recipe manually (without serve.ps1), add the ID to `index.json` in alphabetical order.

5. **Shopping list is lazy** — `renderShopping()` is called when the Shopping tab is visited, and also whenever meal state changes (dish selection, whom toggle, reset, random fill).

6. **Collapsible days** — all days start collapsed. The expand/collapse state is NOT persisted to localStorage (intentional — fresh start on each load).

7. **Stats bar toggle** — `body.hide-nastya-targets` is added on page load so Nastya's row starts collapsed. Clicking either name cell calls `document.body.classList.toggle(...)`. The CSS handles everything else via `body.hide-X-targets` selectors — no JS DOM manipulation needed beyond the class toggle.

8. **Nastya's save also calls `updateStatsDisplay()`** — so her stats row refreshes immediately when her profile is saved in Settings.

9. **AI Chef tab** — currently a "coming soon" placeholder (`panel-assistant`). No AI functionality. Future v2 feature.

10. **PWA** — `manifest.json` + apple-touch-icon meta tags enable "Add to Home Screen". No service worker, so offline support is limited to browser cache.

---

## Potential next features / ideas

- More breakfast recipes (currently only 5 — least variety)
- Weekly macro summary view (total across the week)
- Per-person shopping list split (show Ale's items vs shared vs Nastya's)
- AI Chef tab (Anthropic Claude API via Cloudflare Worker proxy)
- Print-friendly stylesheet
- Drag-and-drop meal reordering
- Favourite/pin recipes
- Nutritional notes per recipe
