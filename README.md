# The Weekly Plate

A personal meal planner for muscle gain. Plan your week, track daily macros, build a consolidated shopping list — built for one person and a pescatarian partner.

**Live app → `https://alessio-timera.github.io/Diet-Management/`**

---

## What it does

- **7-day planner** — pick breakfast, lunch, dinner for each day. Toggle "Me only" or "Both" (girlfriend is pescatarian, so "Both" filters to fish/eggs/dairy dishes only).
- **Auto shopping list** — ingredients aggregate across all selected meals. Shared meals count 2×. Quantities auto-convert (1000 g → 1 kg).
- **Daily macro bars** — calories, protein, carbs, fat vs. your targets. Bars turn plum if you exceed 105%.
- **Recipe book** — 22 built-in recipes + any you add. Filterable by type and dietary flag.
- **Settings** — edit your weight, height, age, goal, and activity level. Macro targets recompute automatically via Mifflin-St Jeor.
- **Export / Import** — download a JSON backup of your week plan and settings; restore it on any device.
- **Installable on phone** — open the site in your phone browser → "Add to Home Screen" → opens full-screen.

---

## Accessing from your phone

1. Enable GitHub Pages: **Repo Settings → Pages → Source: main / root → Save**
2. Open `https://alessio-timera.github.io/Diet-Management/` in your phone browser
3. iOS (Safari): tap the Share icon → "Add to Home Screen"
4. Android (Chrome): tap the menu → "Add to Home Screen" or "Install app"

---

## Running locally

A local server is required because the app fetches recipe JSON files.

```bash
# Python (built into macOS/Linux, available on Windows)
python -m http.server 8000

# or Node
npx serve
```

Then open `http://localhost:8000`.

---

## Adding a new recipe

1. Create a new JSON file in `/recipes/` following this schema:

```json
{
  "id": "d_my_new_dish",
  "name": "My new dish",
  "type": "dinner",
  "time": "25 min",
  "kcal": 700,
  "protein": 48,
  "carbs": 70,
  "fat": 22,
  "pescatarian": false,
  "source": "built-in",
  "ingredients": [
    { "item": "Chicken breast", "qty": 200, "unit": "g",  "cat": "Protein" },
    { "item": "Olive oil",      "qty": 15,  "unit": "ml", "cat": "Pantry"  }
  ],
  "steps": [
    "Season the chicken with salt and pepper.",
    "Cook in a hot pan 4–5 min per side."
  ],
  "tags": []
}
```

**Valid units:** `g`, `kg`, `ml`, `l`, `pc`, `slices`, `cloves`, `tbsp`, `tsp`

**Valid categories:** `Protein`, `Produce`, `Dairy & Eggs`, `Pantry`, `Bakery`, `Frozen`

**pescatarian:** `true` if the dish contains no meat or poultry (fish, eggs, dairy, legumes are fine)

2. Add the recipe `id` to `recipes/index.json`:

```json
[
  "b_oats_yogurt",
  "...",
  "d_my_new_dish"
]
```

3. Commit and push to `main`. GitHub Pages updates within ~1 minute.

---

## Macro targets (how they're calculated)

The app uses the **Mifflin-St Jeor** equation:

```
BMR (male)  = 10×weight + 6.25×height − 5×age + 5
TDEE        = BMR × activity factor  (light = 1.375)
Calories    = TDEE + goal adjustment  (muscle gain = +300 kcal)
Protein     = weight_kg × 1.8 g
Fat         = max(weight×0.7 g, remaining×35%)
Carbs       = remaining calories ÷ 4
```

Edit these in the **Settings** tab.

---

## Chef Assistant (coming in v2)

The AI chef tab is a placeholder. When enabled, it will use the Anthropic Claude API to suggest new recipes that join your recipe book with one click. Setup will require an Anthropic API key and a small serverless proxy (~30 lines) — see [SPEC.md §10.3](./SPEC.md#103-api-proxy-implementation).

---

## Stack

HTML + CSS + vanilla JS. No build step. No frameworks. Recipes stored as JSON files in `/recipes/`. All data persists in `localStorage`. Deployable to GitHub Pages, Netlify, or Vercel with zero configuration.

---

## License

MIT
