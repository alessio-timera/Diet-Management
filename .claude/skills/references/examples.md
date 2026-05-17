# Worked Examples

Three end-to-end examples showing how to convert recipes from different sources. Read these when you encounter an unusual format or want to see how to phrase the explanatory note.

---

## Example 1: HelloFresh page (source has macros, 2 servings)

**Source**: a HelloFresh "Butter Bean Cassoulet" page with stated nutrition (566 kcal, 21g protein, 70g carbs, 21g fat per serving) and a 2-person ingredient list.

**Conversion notes:**
- Page already lists per-serving macros — use directly, don't recompute.
- 2-serving ingredient list → divide all quantities by 2.
- "1 carton of butter beans" for 2 people → 0.5 carton per serving (or convert to grams: ~100g drained).
- "Water for the sauce" → omit from ingredients (tap water, not on shopping list).
- HelloFresh's "from your pantry" section lists oil, salt, pepper — include oil with a realistic quantity (10ml), omit salt/pepper "to taste".
- Veggie dish → `pescatarian: true` (no meat or fish, but qualifies under your filter).
- Tags: `["veggie", "one-pot", "hellofresh"]`.

**Explanatory note to user:**
> Halved every ingredient since the source is a 2-person kit. Macros taken directly from the page. Added 10ml olive oil (the page says "a drizzle" repeatedly) and dropped "water for the sauce" since it's tap water. Marked as pescatarian — the dish is fully vegetarian.

**Fit-check to mention:** "21g protein is low for a muscle-building dinner. Good for sharing with your girlfriend; for solo days you'd want to add tuna or grilled halloumi on the side."

---

## Example 2: Italian food blog (no macros, 4 servings)

**Source**: an Italian blog post for "Parmigiana di Melanzane" — 4 servings, ingredient list and prep steps in Italian, no nutrition info.

**Conversion notes:**
- Italian → translate everything to English. Keep native title with English in parens: `"Parmigiana di Melanzane (Eggplant Parmigiana)"`.
- 4-serving recipe → divide all quantities by 4.
- No macros → estimate from `macros-cheatsheet.md`.
- Frying oil absorption is critical — eggplant soaks up 20-30g per 100g. With ~175g eggplant per serving, that's ~40g of absorbed oil = ~360 kcal of added fat. Don't skip this.
- The page lists "cipolla" (onion) in the ingredients but never uses it in the steps — omit, since the steps don't call for it. Mention this in the note.
- "Basilico" appears in the steps but not the ingredient list — add it (standard parmigiana, can't omit).
- Veggie → `pescatarian: true`.

**Estimated macros (per serving):**
- Eggplant 175g: 44 kcal / 2g P / 10g C / 0.4g F
- Passata 175ml: 52 / 2.5 / 12 / 0.5
- Mozzarella 62g: 175 / 12 / 1.5 / 14
- Parmesan 25g: 100 / 9 / 1 / 7
- Frying oil absorbed (~30ml): 265 / 0 / 0 / 30
- Olive oil for sauce (5ml): 45 / 0 / 0 / 5
- **Totals: ~680 kcal, 26g P, 25g C, 57g F**

**Explanatory note to user:**
> Original recipe is for 4 people — divided every ingredient by 4. The page has no nutrition data, so macros are estimated (±10%). The high fat (57g) comes mostly from frying oil absorbed by the eggplant — if you bake the slices instead, you drop to roughly 450 kcal and 25g fat per serving. Onion is in the original ingredient list but never used in the steps, so I left it out. Added fresh basil since the procedure calls for it even though it wasn't itemized.

**Fit-check:** "Protein-light and fat-heavy — not a regular muscle-building dinner. Great occasional treat, especially shared with your girlfriend (vegetarian, so pescatarian-friendly)."

---

## Example 3: Pasted text (no source, ambiguous servings)

**Source**: user pastes a block of text:

> Quick salmon teriyaki bowl
> - 1 salmon fillet
> - 1 cup rice
> - some broccoli
> - soy sauce, ginger, garlic
> - sesame seeds for garnish
>
> Pan-fry the salmon, steam rice, blanch broccoli, toss everything with teriyaki sauce.

**Conversion notes:**
- Servings not specified — text reads like 1 serving (single fillet, "a cup"). Confirm with user or assume 1.
- Quantities are vague — fill in reasonable per-serving amounts based on context (it's "quick", so single-serving dinner-sized).
- "Teriyaki sauce" not in the ingredient list but mentioned in the steps — add it (~30ml jarred teriyaki per serving) or break down to soy + sugar + ginger if the user wants it from scratch.
- "Some broccoli" → 150g (standard dinner portion).
- "Sesame seeds for garnish" → 5g.
- No macros → estimate.
- Salmon dinner → `pescatarian: true`.

**Estimated macros:**
- Salmon 180g: 360 kcal / 40g P / 0g C / 22g F
- Rice 80g dry: 290 / 6 / 64 / 0.5
- Broccoli 150g: 50 / 4 / 10 / 0.5
- Teriyaki sauce 30ml: ~50 / 1 / 11 / 0
- Sesame seeds 5g + oil for frying 10ml: 120 / 1 / 1 / 13
- **Totals: ~870 kcal, 52g P, 86g C, 36g F**

**Explanatory note to user:**
> The pasted text didn't specify servings — I assumed 1. Filled in plausible quantities for "some broccoli" (150g) and "a cup" of rice (80g dry). Teriyaki sauce was in the steps but not listed, so I added 30ml of jarred sauce. Macros are estimated. This is a solid muscle-building dinner — 52g protein, decent carbs, reasonable fat.

**Note on judgment calls:** When the source is vague, fill in standard portions rather than asking the user about every detail. Flag the choices in the explanatory note so they can adjust.

---

## What good output looks like

Always end your conversion with:

1. **The JSON code block** — clean, valid, in the exact schema.
2. **A 3-6 line explanatory note** — what was scaled, where macros came from, and any non-obvious judgment calls.
3. **A short fit-check** — does this match the user's muscle-building goals? Only if relevant; skip it for breakfasts or obvious wins.

Don't add markdown headers like "## Recipe" or "## Notes" — just go: code block, then a paragraph or two.

## Common mistakes to avoid

- **Forgetting to scale.** A 4-serving recipe gives you a 2,800 kcal "serving" if you forget. Always check the source's serving count first.
- **Skipping oil.** "A drizzle of oil" reads as nothing but adds 50-100 kcal per serving. Include it.
- **Wrong category.** Parmesan goes in `Dairy & Eggs`, not Pantry. Fresh herbs go in `Produce`, dried herbs in `Pantry`.
- **Macros that don't add up.** Always verify with `protein×4 + carbs×4 + fat×9 ≈ kcal`. If you're 30% off, something is miscounted.
- **Pescatarian misclassification.** Search the ingredient list for: chicken, beef, pork, turkey, lamb, bacon, sausage, ham, prosciutto, chorizo, pancetta, duck, veal. If any of those are present, `pescatarian: false`.
- **Reproducing copyrighted text.** When converting from a published source, write the cooking steps in your own words. Don't copy the original prose verbatim — paraphrase the technique into clean imperative instructions.
- **Including ads and filler.** "Get 50% off your first box!" doesn't belong in a cooking step. Strip site chrome aggressively.
