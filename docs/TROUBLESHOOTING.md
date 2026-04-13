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

## `Can't call "createVariableCollection" in read-only mode`

Plugin was initialised while the file was in **Dev Mode**. Figma's
plugin runtime snapshots `figma.editorType` at load time and ignores
later toggles. Relaunching the plugin alone is not enough — the
Desktop process holds the state.

**Fix**:

1. In Figma Desktop, switch the file to Design Mode (보기 → Design으로
   전환, shortcut ⇧D, or top-right `</>` icon).
2. Fully quit Figma Desktop (⌘Q).
3. Reopen the file via `figx files open <key>`.
4. Immediately launch the plugin: `figx plugin open`.
5. Retry the write operation.

Official reference: Figma Plugin API docs on `editorType` and Dev Mode
constraints — https://www.figma.com/plugin-docs/manifest/

## `Quick Actions` (⌘/) doesn't find the plugin

In Dev Mode the ⌘/ palette is a different surface — it lists dev
actions, not plugins. Use the explicit menu path or `figx plugin open`.

## Dev Mode vs Design Mode confusion

|                   | Design Mode                  | Dev Mode                                 |
| ----------------- | ---------------------------- | ---------------------------------------- |
| Purpose           | editing, compositing         | handoff / code inspection                |
| Right sidebar     | Design / Prototype / Inspect | Code / Inspect / Annotations             |
| ⌘/ palette        | includes Plugins             | dev-only (no plugins)                    |
| Variables panel   | full edit                    | read-only                                |
| Plugins submenu   | fully visible                | visible, but some plugins disabled       |
| **Plugin writes** | allowed                      | **blocked — `figma.editorType==='dev'`** |
| Toggle            | top-right `</>` icon         | same icon                                |

If a command works in one mode but not the other, toggle the top-right
`</>` icon. `figx plugin open` works in both **read-only** contexts,
but **writes require Design Mode + full Figma restart** (see above).

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

## Common setup pitfalls (universal)

These are recurring issues across setups. Each has a verified fix.

### 1. `unknown command 'auth'` when running `figma auth login`

`figma` (npm, nvm-managed) shadowed `~/scripts/figma`. Renamed the
binary to **`figx`**; symlinked at `~/.local/bin/figx`. Never call
`figma` — call `figx`.

### 2. `403 Invalid scope(s): file_variables:read`

The Variables REST scopes only appear in the PAT generation UI on
Enterprise plans. On Professional/Organization, switch to the Tokens
Studio plugin path — `figx export tokens` produces a
`tokens.studio.json` the plugin imports directly.

### 3. `plugin not connected` from figma-mcp-go MCP calls

Port `127.0.0.1:1994` was up (MCP server side), but the Figma Desktop
plugin window wasn't running. `figx plugin open` clicks the menu and
resolves it.

### 4. Quick Actions (⌘/) couldn't find the plugin

In Dev Mode the ⌘/ palette is a different surface. Use the explicit
menu path or `figx plugin open`.

### 5. AppleScript failed silently across Figma locales

When Figma Desktop is installed in a non-English locale, English menu
names don't match. figx's plugin automation iterates a locale-name set
(`Plugins / 플러그인 / プラグイン / 插件`), so it works in every
supported language.

### 6. `SSL: CERTIFICATE_VERIFY_FAILED` on excalidraw upload

Homebrew Python doesn't ship CA certs by default. `pip install --user
certifi` then `SSL_CERT_FILE=$(python3 -c 'import certifi; print(certifi.where())')`.
The `tools/docs-sync.sh` sets this automatically.

### 7. `git push` rejected: workflow scope

Happens when committing `.github/workflows/*.yml` without the
`workflow` OAuth scope. Run `gh auth refresh -s workflow` once, then
push.

### 8. `figx: command not found` right after install

`~/.local/bin` not on `$PATH`. Add `export PATH="$HOME/.local/bin:$PATH"`
to your `.zshrc`.

### 9. Figma Desktop menu item missing after manifest import

Plugin imported but Figma hadn't indexed yet. Close and reopen the
file; the plugin will appear under `Plugins → Development`.

### 10. Variable / Rectangle / anything write → "read-only mode"

Full Desktop restart required. Background: Figma plugins snapshot
`figma.editorType` at load; Dev Mode loads mean permanent read-only
for that plugin session. ⌘Q Figma → reopen file → switch to Design
Mode → launch plugin.

## Policy

Whenever an error repeats more than twice, **stop and check official
documentation** before trying variations. Training data on plugin APIs
goes stale — platform-enforced rules (editor modes, PAT scopes, rate
limits) ship quarterly. Sources:

- Figma Plugin API — https://www.figma.com/plugin-docs/
- Figma REST API — https://developers.figma.com/docs/rest-api/
- Figma Plugin Manifest — https://www.figma.com/plugin-docs/manifest/
- figma-mcp-go issues — https://github.com/vkhanhqui/figma-mcp-go/issues
