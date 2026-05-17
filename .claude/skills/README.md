# recipe-to-json — Installation & Usage

A Claude Skill that converts any recipe (URL, pasted text, photo, foreign-language blog) into the standardized JSON format used by The Weekly Plate.

## What's inside

```
recipe-to-json/
├── SKILL.md                          # Main skill file — when to trigger, procedure, rules
├── references/
│   ├── macros-cheatsheet.md          # Per-100g macros for ~80 common ingredients
│   └── examples.md                   # Three worked conversions to learn from
└── README.md                         # This file
```

## How to install

You have three options depending on where you want to use it.

### Option 1 — Claude.ai (web/desktop app) as a user skill

1. Go to claude.ai → Settings → Capabilities → Skills.
2. Click "Create skill" (or "Upload skill" if you have a `.skill` package).
3. If creating from scratch: paste the contents of `SKILL.md` into the editor and add the `references/` files as attached resources.
4. Save. The skill will now trigger automatically whenever you paste a recipe URL or mention converting a recipe.

Note: user skills in Claude.ai are a relatively new feature. If you don't see the option in Settings, check Anthropic's docs at https://support.claude.com — the feature may roll out gradually.

### Option 2 — Claude Code (CLI)

If you use Claude Code in your terminal:

1. Drop the entire `recipe-to-json/` folder into your project's `.claude/skills/` directory (or your user-level `~/.claude/skills/` for it to apply everywhere).
2. Claude Code will detect it on the next session.
3. Test it: `claude "convert this recipe to JSON: <URL>"`.

### Option 3 — Project knowledge (no skills feature needed)

If you don't have access to user skills yet, you can still use this as a regular reference:

1. Create a Project in Claude.ai (the feature for keeping reusable context).
2. Upload `SKILL.md`, `references/macros-cheatsheet.md`, and `references/examples.md` to the project's knowledge.
3. Add a Project Instruction like: *"When I share a recipe in any form, follow the procedure in SKILL.md to convert it to JSON."*
4. Now every chat in that project will use the skill.

This works today, doesn't require any feature access, and behaves nearly identically.

## How to use it

Once installed, just share a recipe in any way:

- "Convert this to JSON: https://blog.giallozafferano.it/.../parmigiana-melanzane/"
- "Here's a recipe I want to add: [pasted text]"
- "Take this and put it in my format" + screenshot of a cookbook page
- "Add the salmon teriyaki bowl from BBC Good Food"

Claude will:
1. Fetch / read the source.
2. Scale to single serving.
3. Normalize ingredients with correct units and categories.
4. Compute or estimate macros.
5. Return clean JSON + a short note explaining any judgment calls.

## What to expect

The skill produces JSON that drops straight into your `BUILT_IN_DISHES` object (or AI-recipe library) in The Weekly Plate. Each recipe is per single serving, metric units, with macros that add up correctly.

When macros are estimated (the source has no nutrition data), the skill says so explicitly. When the recipe is a poor fit for muscle-building goals, the skill mentions it neutrally — but converts it anyway, since that's your call.

## Updating the skill

The macros cheatsheet and examples are independent files. To add an ingredient that comes up often or include a new edge case, edit those files directly — you don't need to touch `SKILL.md`. The main file just references them.

If you want to change the schema itself (e.g., add a `difficulty` field), edit the `### Field rules` section of `SKILL.md` and the "Output Schema" code block.

## Testing it

After installing, try these three test prompts to make sure it works:

1. **URL test**: paste any HelloFresh recipe URL.
2. **Foreign language test**: paste a recipe URL from an Italian or French blog.
3. **Vague text test**: paste 3-4 lines of casual recipe description ("salmon with rice and broccoli, pan-fry the salmon...").

If all three return valid JSON in the schema with reasonable macros and a clear explanatory note, the skill is working.
