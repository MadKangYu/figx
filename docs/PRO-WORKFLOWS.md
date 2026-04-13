# How Figma experts actually work

> Patterns observed from top design-system teams (Atlassian, Shopify
> Polaris, GitHub Primer, Spotify Encore, Vercel Geist). What they do
> that the beginner tutorials don't say.

## 1. Code is the source of truth, not Figma

Beginners: draw in Figma, eyeball the hex values, hand-code them.
Experts: keep token constants in code (JS/TS/JSON/Python), generate
Figma Variables from them, treat Figma as a rendering surface.

- figx pattern: `tools/extract_from_py.py` reads Python constants → 3
  token formats. Code changes first, Figma follows.
- Big-team pattern: a `design-tokens` repo is the hub; Figma + web +
  iOS + Android all consume from it via Style Dictionary.

## 2. Variables before Styles — always

Styles (Paint/Text/Effect) are frozen snapshots. Variables are live
references. Experts bind every style to a Variable so a single mode
swap re-skins the whole library.

- Correct shape:
  ```
  Color/SKU (Variable)  ──bound──►  Paint style (Primary CTA)
                                    │
                                    └─ used in every button component
  ```
- Never: hard-coded hex in a paint style.

## 3. One base library, many branded files

Experts don't duplicate components per brand — they publish **one
base library** and make brand-specific files that:

1. Subscribe to the base library.
2. Override only the Variables that differ (e.g., `primary-500` for
   Pep vs Cer).
3. Get every structural update for free.

This is the pattern Tokens Studio's `$themes` + figx's `Color/SKU`
collection encodes.

## 4. Branching for every non-trivial change

Professional+ gets Figma Branching. Experts treat `main` the same as
code — every real change goes to a branch, reviewers comment, merge
back.

- `figx files find` handles branch URLs already (Figma branch URLs
  parse as their own file keys).
- Publish only from `main` after a review merge.

## 5. Dev Mode is not optional — it's the handoff contract

- Use **Dev Mode links** (`?mode=dev`) exclusively for engineers.
  Adds Code / Inspect panels; surfaces Annotations.
- Pin measurements + annotations so values don't drift between
  review sessions.
- Expose `Dev Resources` with direct links to the coded components
  (the REST API endpoint figx wraps).

## 6. Automation that actually runs

Experts don't schedule "weekly token audits." They wire:

| Trigger                   | What runs                                                              |
| ------------------------- | ---------------------------------------------------------------------- |
| Library publish           | Figma Webhook → CI → `figx export tokens --fmt css` → auto-PR          |
| PR merge to design-tokens | `figx vars apply` (Enterprise) or Tokens Studio `Push` (everyone else) |
| Nightly                   | `figx doctor` + `figx hermes check` → alerts if drift                  |

`bootstrap.sh` already wires the Hermes `figma-tokens` route for
step-by-step ping.

## 7. The "variable ladder" — don't invent ad-hoc tokens

Experts refuse to make one-off tokens (`button-primary-ceramide-hover-dark`).
They build a ladder:

```
Base  →  Semantic  →  Component-specific
#0A0A0A  color-base-black  button-bg
```

Figma Variables let you alias one variable to another. The ladder
keeps the library sane.

## 8. Components have slots, not duplicates

For each component (Button, Card, Badge) experts define **one master
set of variants** (size × state × intent) plus slots. They never
duplicate the component to reskin — they bind the slot's color
property to a Variable and let the mode swap do the work.

## 9. Measure what ships, not what's drawn

- Pro Enterprise teams run the **Library Analytics** REST API weekly
  to see which components / variables actually get used downstream.
  Kill the ones that don't.
- Non-Enterprise: Figma's in-app library stats panel (less granular
  but still useful).

## 10. The "one-way trip" rule

Once a token lands in a release, changing its meaning is a breaking
change — treat it like a public API. Add new tokens, deprecate old
ones, run a migration window. figx's CHANGELOG convention exists
because it's the first place consumers look.

## 11. Accessibility gate, always on

- Contrast plugin runs on every palette change.
- Minimum target size enforced by an Auto-Layout component.
- Semantic naming: never call it "red" — call it "danger". Colorblind
  users + future rebrands both thank you.

## 12. Multiplayer is a feature, not a bug

Experts accept that 5 people will be in the file at once. Rules:

- Lock published components.
- Use `Component Sets` with variants instead of "my version" files.
- Leave a "work-in-progress" page that doesn't publish; promote to
  the published page via copy+paste-in-place once ready.

## 13. The review loop is daily, not quarterly

- 15-minute async review over shared comments in Dev Mode URLs.
- Publish-library-with-message describing what changed (this is
  `figx publish`'s "commit message" equivalent).
- Retrospective after every major token refactor — what broke, what
  didn't.

## 14. Tool stack (what expert designers actually use)

| Tool                      | Role in the pro workflow                                |
| ------------------------- | ------------------------------------------------------- |
| Figma + Tokens Studio     | source of Variables (if not Enterprise REST)            |
| Style Dictionary          | token distribution to web/iOS/Android                   |
| Figma MCP                 | AI-driven inspection & code generation (via v0, Cursor) |
| Figma MCP Go              | agent-driven Figma editing                              |
| Contrast                  | accessibility gate                                      |
| Chromatic or Lost Pixel   | visual regression on the coded side                     |
| Storybook                 | the coded-component side of the library                 |
| Hermes / Slack / Telegram | event routing                                           |
| figx                      | the orchestrator that wires the above together          |

## 15. Beginner → pro delta

| Skill       | Beginner                      | Pro                                          |
| ----------- | ----------------------------- | -------------------------------------------- |
| Tokens      | hex values everywhere         | one Variables library, modes for brand swaps |
| Libraries   | copy components between files | subscribe + override                         |
| Handoff     | screenshots in Slack          | Dev Mode links + annotations                 |
| Review      | PM in the file at night       | async Dev Mode comments during day           |
| Releases    | "new version" file            | library publish + version message            |
| Change mgmt | ad-hoc rename                 | deprecation window + migration doc           |
| Automation  | none                          | webhooks → CI → auto-PR                      |
| Measurement | gut feel                      | Library Analytics + usage dashboards         |

## Bottom line

Experts don't draw faster. They draw less — because the token
pipeline, library inheritance, and Dev Mode contracts mean one change
propagates everywhere. figx exists to make that pipeline cheap enough
to set up even on smaller teams.
