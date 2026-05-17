---
name: recipe-to-json
description: Convert any recipe (from a URL, pasted text, photo, or PDF) into The Weekly Plate's standardized JSON format with normalized ingredients, per-serving macros, and structured cooking steps. Use this skill whenever the user shares a recipe in any form — a link to a food blog, HelloFresh/BBC Good Food/Serious Eats page, a screenshot of a cookbook, pasted text from a chat, an Italian/French/Spanish recipe in another language, or just describes a dish — and wants it added to their recipe library. Trigger this skill even if the user only says "convert this", "add this recipe", "turn this into JSON", "give me this in my format", or pastes a recipe URL without further instruction. Also use when the user asks to translate a foreign-language recipe, scale a multi-serving recipe down to one portion, estimate calories/macros for a recipe that lacks nutrition info, or normalize messy/inconsistent ingredient lists into clean structured data.
---

# Recipe to JSON

Converts a recipe from any source into The Weekly Plate's standardized JSON schema — single serving, metric units, macros included, ingredients categorized for shopping-list aggregation.

## When this skill applies

Trigger this skill whenever the user:
- Shares a recipe URL (food blog, HelloFresh, BBC, Serious Eats, AllRecipes, etc.)
- Pastes raw recipe text from anywhere
- Uploads a screenshot or PDF of a recipe
- Describes a dish they want structured
- Asks to translate a foreign-language recipe into the format
- Wants to scale a recipe down to one serving

Don't trigger for: chatting *about* recipes, asking for recipe recommendations without source material, or general nutrition questions. This skill is specifically for *converting existing recipe content* into the schema.

## The output schema

Every recipe converts to this exact JSON structure:

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
    { "item": "Chicken breast",  "qty": 200, "unit": "g",      "cat": "Protein"      },
    { "item": "Olive oil",       "qty": 15,  "unit": "ml",     "cat": "Pantry"       },
    { "item": "Garlic",          "qty": 2,   "unit": "cloves", "cat": "Produce"      },
    { "item": "Cherry tomatoes", "qty": 150, "unit": "g",      "cat": "Produce"      },
    { "item": "Parmesan cheese", "qty": 20,  "unit": "g",      "cat": "Dairy & Eggs" }
  ],
  "steps": [
    "Step one.",
    "Step two.",
    "Step three."
  ],
  "tags": []
}
```

### Field rules

- **`id`** — slug starting with the meal type letter: `b_` (breakfast), `l_` (lunch), `d_` (dinner). Lowercase, underscores, no special characters. Derive from the dish name. Example: "Eggplant Parmigiana" → `d_parmigiana_melanzane` or `d_eggplant_parmigiana`.
- **`name`** — human-readable title, in English. For foreign recipes, use the native name and append English in parentheses: `"Parmigiana di Melanzane (Eggplant Parmigiana)"`.
- **`type`** — exactly one of: `"breakfast"`, `"lunch"`, `"dinner"`. If unclear, infer from cuisine and macros (light + sweet → breakfast; heavier savory → lunch/dinner). If still ambiguous, ask the user.
- **`time`** — total active + cooking time, e.g. `"30 min"`. Don't count overnight soaking or marinating unless it's mandatory.
- **`kcal` / `protein` / `carbs` / `fat`** — numbers, per single serving. See [Macro Calculation](#macro-calculation).
- **`pescatarian`** — `true` if no meat or poultry (fish, eggs, dairy, legumes are fine). `false` if it contains chicken, beef, pork, turkey, lamb, etc.
- **`source`** — always `"built-in"` for skill output (the app uses `"ai"` for in-chat suggestions).
- **`ingredients`** — array, see [Ingredient Normalization](#ingredient-normalization).
- **`steps`** — array of strings, see [Step Writing](#step-writing).
- **`tags`** — array, can be empty. Suggested vocabulary: `"italian"`, `"asian"`, `"mexican"`, `"mediterranean"`, `"veggie"`, `"one-pot"`, `"batch-cook"`, `"quick"`, `"comfort-food"`, `"high-protein"`, `"low-carb"`, plus a source tag like `"hellofresh"` or `"giallozafferano"` when relevant.

## Procedure

### 1. Get the source material

- **If a URL**: use `web_fetch` to retrieve the page. If it fails (URL too long, paywall), search for the recipe by name and try the canonical URL.
- **If a file**: read it. For photos/PDFs of recipes, the content arrives as an image in context — read it directly.
- **If pasted text**: use as-is.
- **If a description only**: confirm with the user before fabricating quantities.

### 2. Extract the raw data

Pull out:
- Recipe name and language
- Stated number of servings (critical — see step 3)
- Full ingredient list with quantities
- Cooking steps
- Stated nutrition info, if any
- Total time
- Cuisine / category hints (the page's tags, breadcrumbs, etc.)

### 3. Scale to one serving

Most recipes are for 2, 4, or 6 people. The schema is **per single serving**. Divide every ingredient quantity by the stated serving count. Round sensibly: 175g of eggplant, not 174.83g. Macros (kcal/protein/carbs/fat) are also per single serving — if the source lists "per serving" macros, use them as-is; if it lists total, divide.

**Don't divide the cooking time.** A 30-minute recipe takes 30 minutes whether you cook for 1 or 4.

### 4. Normalize ingredients

See [Ingredient Normalization](#ingredient-normalization) below for the full ruleset.

### 5. Compute or estimate macros

See [Macro Calculation](#macro-calculation) below.

### 6. Write the steps

See [Step Writing](#step-writing) below.

### 7. Validate

Before returning, mentally check:
- Macros add up: `protein×4 + carbs×4 + fat×9 ≈ kcal` (within ±15%)
- Every ingredient has a valid unit and category
- Steps reference all key ingredients
- `pescatarian` flag matches the actual ingredients (search for meat words: chicken, beef, pork, turkey, lamb, bacon, sausage, ham, prosciutto, chorizo, etc.)
- The `id` is unique and slugified properly

### 8. Output

Return the JSON in a code block with `json` syntax highlighting. Add a brief explanatory note covering:
- What was scaled / converted
- Where macros came from (source's own data vs. estimated)
- Any judgment calls (omitted ingredients, substitutions, ambiguous unit conversions)
- A fit-check against the user's goals (muscle building, 45-55g protein per dinner) if it's relevant

## Ingredient Normalization

### Units

Use only these units. Convert anything else.

| Unit | Use for |
|---|---|
| `g` | Solids by weight under 1000g |
| `kg` | Solids 1kg or more (rare per-serving) |
| `ml` | Liquids under 1000ml |
| `l` | Liquids 1l or more |
| `pc` | Whole countable items (1 onion, 1 lemon) |
| `slices` | Bread, deli meat |
| `cloves` | Garlic only |
| `tbsp` | Tablespoons — sauces, oils when imperial source forces it |
| `tsp` | Teaspoons — spices, small seasoning |

**Conversion table** for common imperial → metric:
- 1 cup flour ≈ 125g
- 1 cup sugar ≈ 200g
- 1 cup rice ≈ 200g
- 1 cup milk ≈ 240ml
- 1 cup water ≈ 240ml
- 1 oz ≈ 28g
- 1 lb ≈ 450g
- 1 fl oz ≈ 30ml
- 1 stick butter ≈ 113g

### Categories

Every ingredient gets one of exactly six categories (matches the app's shopping-list grouping):

| Category | Contains |
|---|---|
| `Protein` | Fresh meat, poultry, fish, seafood, tofu, tempeh, canned tuna/salmon, deli meats |
| `Produce` | All fresh fruits, vegetables, fresh herbs, garlic, onions, potatoes, mushrooms |
| `Dairy & Eggs` | Milk, butter, yogurt, cheese (all kinds), eggs, cream, cottage cheese |
| `Pantry` | Dry goods, oils, vinegars, canned beans/tomatoes, pasta, rice, grains, spices, sugar, flour, honey, sauces, stocks, dried herbs, nuts |
| `Bakery` | Bread, tortillas, pita, ciabatta, buns, breadcrumbs, croutons |
| `Frozen` | Frozen veg, frozen fruit, frozen seafood explicitly sold frozen |

**Gotchas:**
- Fresh herbs (basil, parsley, cilantro) → **Produce**, not Pantry
- Dried herbs (oregano, thyme, bay leaf) → **Pantry**
- Canned beans/tomatoes → **Pantry**
- Frozen peas → **Frozen** (only if recipe specifies frozen)
- Parmesan → **Dairy & Eggs**, not Pantry
- Lemon → **Produce** (whole), but lemon juice from a bottle → **Pantry**

### Item names

- Capitalize the first word: `"Chicken breast"` not `"chicken breast"`.
- Be specific where it matters: `"Greek yogurt (0-2% fat)"` not just `"Yogurt"` — the protein content differs hugely.
- Don't include cooking notes in the name. `"Garlic"` not `"Garlic, minced"`. The prep belongs in the steps.
- For unusual ingredients, add a clarifier in parentheses: `"Mozzarella (fior di latte)"`, `"Tomato passata (sieved tomatoes)"`.

### Quantities — common judgment calls

- **"A drizzle of olive oil"** → 5-10ml (estimate 5ml for sautéing, 10-15ml for dressing).
- **"To taste"** salt and pepper → omit from the ingredient list unless it's a significant amount (e.g., the recipe specifies 1 tsp salt for pasta water — that's not "to taste").
- **"For frying"** oil — eggplant and breaded items absorb ~10-15% of frying oil weight. Estimate 20-30ml absorbed per serving for deep-fried dishes.
- **Water for the sauce / pasta water** — omit from ingredients (it's tap water, not on the shopping list).
- **Garlic clove sizes vary** — assume 1 clove ≈ 3-5g.
- **"1 onion"** → use `1 pc`. Medium onion ≈ 150g if grams are needed elsewhere.

## Macro Calculation

### If the source provides per-serving macros

Use them. Round to whole numbers. Verify they roughly add up (`protein×4 + carbs×4 + fat×9 ≈ kcal` ±15%). If they're wildly off, trust kcal and protein, recompute carbs/fat.

### If the source provides total macros only

Divide by the stated serving count.

### If the source provides no macros

Estimate from a per-ingredient lookup. Use `references/macros-cheatsheet.md` (in this skill folder) for standard per-100g values of common ingredients. Sum them across the recipe.

The estimation is approximate (±15% is fine). Always tell the user when macros are estimated vs. taken from the source.

**Cooking adjustments worth knowing:**
- Fried foods absorb ~10-15% of their weight in oil → significant added fat & kcal
- Roasting/baking doesn't add meaningful macros beyond what's in the recipe
- Pasta/rice macros are usually given **dry** — that's correct for this schema

## Step Writing

- Number is implicit (it's an array — don't write "1. " "2. ").
- Keep each step to 1-3 sentences, one logical phase per step.
- Use imperative voice: `"Slice the onion."` not `"You should slice the onion."`.
- Combine micro-actions: `"Peel and grate the garlic. Trim the green beans."` is one step.
- Include cooking times and visual cues: `"Sauté 4 min until softened."` not `"Sauté."`.
- Strip site-specific filler: tips, "wash hands after raw chicken" warnings, ads, photo captions, "the secret is...", brand mentions like "I love using HelloFresh stock paste".
- Keep technique-relevant tips: `"Don't crowd the pan or the chicken will steam instead of sear."` is useful.
- For multi-language sources, translate to clean English. Use standard culinary English (sauté, simmer, dice).

## Special cases

### Multi-component recipes (recipe + sauce + side)

If the recipe has separable parts (e.g., "Chicken with lemon sauce, served with roasted vegetables"), treat the whole thing as one dish. List all ingredients in one array, all steps in sequence.

### Recipes with mandatory pantry items not on the page

Some recipe pages (HelloFresh especially) list "you'll need from your pantry: olive oil, salt, pepper, sugar, water". Include these in the ingredients array with realistic quantities. Salt/pepper "to taste" can be omitted; specific amounts should be included.

### Foreign-language recipes

Translate the recipe name (keep native title with English in parens), all ingredients, and all steps to English. Don't translate proper food names that are universal: `"Parmigiano Reggiano"` stays as is, not "Parmesan from Reggio Emilia".

### Recipes that don't fit muscle-building goals

If a recipe is very low-protein or very high-fat, mention it neutrally in the explanatory note after the JSON. Don't refuse to convert it — the user gets to decide what's in their library.

### Photos and PDFs of recipes

Read the image directly. If text is unclear (handwritten cookbook, blurry photo), state what you couldn't read and either ask the user or make a reasonable estimate (clearly flagged as such).

## Output format

Always return:

1. A `json` code block with the full recipe object
2. A short explanatory note (3-6 lines) covering scaling, macro source, and any judgment calls
3. If the recipe is a poor fit for the user's goals, a brief honest fit-check

Don't return:
- Markdown headers above the JSON ("## Recipe", "## Ingredients" etc.)
- Multiple JSON blocks for "variations" unless asked
- Lengthy explanations of why you made each choice — just flag the non-obvious ones

## References

- `references/macros-cheatsheet.md` — per-100g macros for common ingredients, used when the source has no nutrition info. **Read this whenever you need to estimate macros from ingredients.**
- `references/examples.md` — three full worked examples (HelloFresh, an Italian blog, a pasted text recipe) showing the conversion in action. **Read this when you encounter an unusual source format or want to see how judgment calls are explained to the user.**
