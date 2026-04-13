# How world-class design teams use Figma

> Observable patterns from public case studies, Config talks, and
> open-source design systems. Not anecdotes — every bullet maps back
> to a published artifact or a figx feature you can use today.

## Shopify — Polaris

- **Tokens in GitHub, not Figma.** `shopify/polaris` publishes the
  token manifest as an npm package; Figma library just mirrors it.
  - figx parallel: `tools/extract_from_py.py` — code is SSOT.
- **Semantic naming only.** `text-subdued`, `surface-hovered`; no
  hex leaks into components.
- **Cross-surface handoff.** Same Variables drive web (React),
  Polaris for Flutter, and admin email templates.
- **Tokens Studio** was the bridge before Variables — today they use
  both (Variables in file, Tokens Studio for Git round-trip).

## GitHub — Primer

- **Primer Prism** for color ramps. Every color derives from a base
  via math — never eyeballed.
- **Primitives → Functional → Component.** Three Variable layers:
  global primitives, semantic functional, component-scoped
  overrides.
- **Public design-tokens repo** feeds Figma + CSS + Rails + Swift.
  - figx parallel: `docs/PRO-WORKFLOWS.md §7` — variable ladder.
- **Dev Mode annotations** pinned on every shipped component.

## Spotify — Encore

- **Mode swap for density.** Instead of Pep/Cer, Encore swaps
  `comfortable / compact / mobile` density modes on the same
  Variables collection. Same pattern figx uses for SKU.
- **Design reviews in Dev Mode URLs** with Variables panel open.
- **Token Explorer plugin** internally used for drill-down; they've
  open-sourced parts.

## Vercel — Geist

- **Geist design tokens** live in `vercel/geist`. Figma library is
  auto-generated from the TS source on every commit via a GitHub
  Action that runs Style Dictionary + Tokens Studio push.
- **v0.dev trained on Geist.** Because tokens live in code, v0 can
  produce on-brand components without looking at Figma at all.
  - figx parallel: `docs/INTEGRATIONS.md → v0` — point v0 at
    `tokens.css`.
- **Zero-click handoff.** Dev Mode link → `Ctrl+C` the Tailwind
  class names directly.

## Atlassian — Design System

- **Multi-brand with modes.** Jira, Confluence, Trello all share
  one component library. Variables modes isolate brand differences.
- **Token validation in CI.** Every token change runs contrast checks
  - a visual diff against Storybook.
- **Figma branching** is the default for any non-trivial work; main
  is protected.

## Airbnb — DLS (Design Language System)

- **Published schema.** Tokens follow a published JSON schema with
  strict types — a token PR that violates types fails CI.
- **Accessibility gates** on every Variable update (Contrast plugin
  at authoring time, axe-core on the coded side).
- **Figma is not the source** — it's the presentation layer. All
  tokens flow from `dls-tokens` into web, iOS, Android, emails.

## Stripe

- **Chromatic visual regression** on the coded side; Figma library
  only updates after the coded counterpart is green.
- **Library Analytics (Enterprise)** surfaces dead components — if
  a component's usage dropped below a threshold, it's deprecated.
- **Annotations > screenshots.** Every shipping spec is annotated
  in Dev Mode; PMs stopped taking screenshots to Slack three years
  ago.

## Common patterns (what every one of them does)

1. **Code is SSOT, Figma mirrors it.** Not the other way around.
2. **Variables modes carry the brand/density/theme axis.** One
   library, many surfaces.
3. **Tokens Studio or REST** to push tokens, never manual entry.
4. **Branching + review** for every non-trivial change.
5. **Dev Mode is the handoff surface**, not Slack screenshots.
6. **Accessibility is a pre-commit gate**, not an afterthought.
7. **Library Analytics or equivalent** culls dead components.
8. **Automation on publish** — library publish → CI → auto-PR in
   the code repo.
9. **Semantic naming** — no colors named after their hex.
10. **Handoff via annotations** — every commitment is written, not
    verbal.

## figx mapping

| Pattern                         | figx command                                        |
| ------------------------------- | --------------------------------------------------- |
| Code-first tokens               | `tools/extract_from_py.py` → `figx export tokens`   |
| Variables via Tokens Studio     | `tokens.studio.json` output                         |
| Variables via REST (Enterprise) | `figx vars apply`                                   |
| Publish library                 | `figx publish`                                      |
| Dev Mode handoff                | `figx devmode`                                      |
| Webhook → CI                    | Hermes `figma-tokens` route                         |
| MCP-driven edits                | `figx plugin open` + figma-mcp-go                   |
| Accessibility check             | `Contrast` plugin + `docs/PRO-WORKFLOWS.md §11`     |
| Analytics                       | Figma REST `/v1/analytics/libraries/*` (Enterprise) |

## What they don't do

Equally telling:

- They don't duplicate files per brand.
- They don't color-pick from screenshots.
- They don't use Figma as a whiteboard (FigJam for that).
- They don't let designers commit directly to main without review.
- They don't track specs in Notion — they live in Dev Mode.
- They don't name tokens after their value.

## The gap between "using Figma" and "using Figma well"

Three quick tests:

1. **Delete every hex in your design files.** Can you re-theme the
   product by swapping one Variables mode? Yes = you're operating
   like Spotify Encore. No = you have work to do.
2. **Remove the designer from the handoff meeting.** Can engineering
   still ship the feature from the Dev Mode link alone? Yes = Stripe
   level. No = handoff debt.
3. **Rebrand in under a day.** Add a new Variables mode, flip, done.
   Yes = Atlassian-grade. No = you copy components between files.

figx aims to make test #1 and #2 cheap; test #3 is a library
architecture question this CLI won't solve by itself, but the token
pipeline is the foundation.
