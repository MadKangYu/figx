# Troubleshooting

## `unknown command 'auth'` when running `figma auth login`

`npm` ships a `figma` binary that shadows our intended path. **Always use
`figx`** (named so precisely to avoid this collision). Run `which -a figma`
to see the overlap; `which figx` must point to `~/.local/bin/figx`.

## `403 This endpoint requires the file_variables:read scope`

Your workspace plan doesn't expose the Variables REST API. Figma only
unlocks `file_variables:read|write` for Enterprise Full seats.

Work-around — use the plugin path instead of REST:

```bash
figx export tokens --fmt dtcg  --out tokens.dtcg.json
figx export tokens --fmt css   --out tokens.css
# And, from your token pipeline:
python3 tools/extract_from_py.py --src <your_source.py> --out <out_dir>
```

Then in Figma Desktop, open **Tokens Studio for Figma** and `Tools →
Load from file system` → pick the generated `tokens.studio.json`,
activate a theme, press **Push to Figma**. This produces real Figma
Variables (with Pep/Cer modes) on any paid plan.

## `plugin not connected`

The Figma Desktop plugin window isn't open. Run:

```bash
figx plugin open
```

It clicks `Plugins → 개발 → Figma MCP Go` through the menu (not Quick
Actions, which fails under some locales / Dev-Mode overlays).

## `Accessibility permission required` from `figx plugin open`

macOS blocks `System Events` until your terminal is approved:

1. System Settings → Privacy & Security → Accessibility
2. Add Terminal (or iTerm / Ghostty / VS Code) and toggle **on**
3. Re-run `figx plugin open`

## `Quick Actions` (⌘/) doesn't find the plugin

In Dev Mode the ⌘/ palette is a different surface — it lists dev
actions, not plugins. Use the explicit menu path or `figx plugin open`.

## Dev Mode vs Design Mode confusion

|                 | Design Mode                  | Dev Mode                           |
| --------------- | ---------------------------- | ---------------------------------- |
| Purpose         | editing, compositing         | handoff / code inspection          |
| Right sidebar   | Design / Prototype / Inspect | Code / Inspect / Annotations       |
| ⌘/ palette      | includes Plugins             | dev-only (no plugins)              |
| Variables panel | full edit                    | read-only                          |
| Plugins submenu | fully visible                | visible, but some plugins disabled |
| Toggle          | top-right `</>` icon         | same icon                          |

If a command works in one mode but not the other, toggle the top-right
`</>` icon. `figx plugin open` works in both.

## `429 rate limited`

`figx` retries 429/5xx with exponential backoff (5 attempts). If you see
it consistently, reduce concurrency — don't spawn more than one
`figx vars apply` at a time.

## `PAT rejected`

- Whitespace — paste cleaned the token? The CLI validates against `/v1/me`
  before storing; if rejected, regenerate.
- Expired — Figma PATs have a 90-day max (April 2025 policy).

## `figx plugin status` says WS up, but MCP says plugin not connected

WebSocket is open but the Figma Desktop plugin hasn't handshaken yet.
The plugin needs to be actively running in Figma — `figx plugin open`
re-clicks the menu item.

## Reset everything

```bash
figx auth logout
rm -f ~/.config/figma/cli.toml
rm -f ~/.local/state/figma-cli/events.log
figx doctor
```
