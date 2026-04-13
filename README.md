# figx — the Figma pipeline you'll actually keep using

<p align="left">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="platform" src="https://img.shields.io/badge/platform-macOS-lightgrey">
  <img alt="shell" src="https://img.shields.io/badge/shell-bash-89e051">
  <a href="CHANGELOG.md"><img alt="version" src="https://img.shields.io/badge/version-0.1.0-orange"></a>
  <a href="https://github.com/MadKangYu/figx/stargazers"><img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/MadKangYu/figx?style=social"></a>
</p>

> **For Figma Professional / Organization / Enterprise users.**
> A lean macOS CLI that turns your design-token source of truth into real
> Figma Variables, launches the `figma-mcp-go` plugin for you without
> hunting through menus, and streams every step into Hermes-Agent.
> Built because shipping a token update shouldn't cost you fifteen
> clicks every time.

## What figx does (TL;DR)

| If you need to…                                                            | Run                                                                                     |
| -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Set up everything on a fresh Mac, without thinking                         | `bash <(curl -fsSL https://raw.githubusercontent.com/MadKangYu/figx/main/bootstrap.sh)` |
| Know if your environment is ready                                          | `figx doctor`                                                                           |
| Audit macOS permissions (Accessibility / Automation / Keychain / outbound) | `figx permissions`                                                                      |
| Save a PAT safely (Keychain + `/v1/me` validation)                         | `figx auth login`                                                                       |
| Register `figma-mcp-go` to Claude Code + Codex + OpenCode at once          | `figx plugin register-mcp all`                                                          |
| Import the Figma Desktop plugin **automatically** (no UI hunting)          | `figx plugin install`                                                                   |
| Launch the already-imported plugin via menu click                          | `figx plugin open`                                                                      |
| Extract tokens from Python code to DTCG / CSS / Tokens Studio JSON         | `figx export tokens --fmt dtcg`                                                         |
| Apply Variables to Figma (Enterprise)                                      | `figx vars apply tokens.json`                                                           |
| Walk through the 7-step wizard                                             | `figx onboarding`                                                                       |
| Check for Figma Desktop updates                                            | `figx figma-update`                                                                     |
| Find / initialize a figx project folder                                    | `figx project find` · `figx project init`                                               |
| Publish a library and poll for completion                                  | `figx publish`                                                                          |
| Ping Hermes on anything                                                    | `figx hermes notify "…"`                                                                |

Each command is idempotent, has `--help`-style output on invalid input,
and pushes a Hermes event (logged locally if Hermes isn't reachable).

---

## Why figx

You already pay for a plan that unlocks multi-mode Variables, code
connect, and libraries. What you don't have is a clean way to keep them
in lockstep with your codebase — Figma's own CLI offering is minimal,
Tokens Studio still needs a wizard, and `figma-mcp-go` needs a plugin
window that never quite stays open. `figx` stitches all three into a
single hybrid pipeline that:

- **Reads your design tokens from code** (Python constants via AST, no
  execution), and emits W3C DTCG + CSS + Tokens Studio payloads in one
  pass.
- **Launches the Figma plugin for you**, clicking `Plugins → 개발 →
Figma MCP Go` through a locale-independent AppleScript menu
  traversal. No Quick Actions, no lost focus.
- **Keeps secrets in the Keychain**, validates before storing, and
  refuses to retry 401/403 so you never burn through a 90-day PAT
  debugging scopes.
- **Talks to Hermes-Agent** on every event — starts, successes,
  failures — so your phone pings when a publish finishes even if you
  walked away.

## Architecture at a glance

[![hybrid pipeline](https://img.shields.io/badge/open%20in-Excalidraw-6965db?style=flat)](https://excalidraw.com/#json=_ZstONCsu_jsD2-83qhQ3,8REr9ToG-GU9R52HdA8dYA)

Drop-in editable diagram at
[`assets/diagrams/figx-architecture.excalidraw`](assets/diagrams/figx-architecture.excalidraw)
or open the live link above.

## Core features in action

Each block below is actual output from this machine. They're what you
get.

### 1. `figx doctor` — checks everything before you start

```
→ figma-cli doctor
  ✓ curl
  ✓ jq
  ✓ security
  ✓ gh
  ✓ Keychain PAT
  ✓ config: /Users/yu/.config/figma/cli.toml
  ✓ hermes Hermes Agent v0.8.0 (2026.4.8)
```

### 2. `figx auth status` — PAT lives in Keychain, not in your shell history

```
✓ PAT present in Keychain (service=figma-cli)
```

### 3. `figx files current` — your working file, remembered

```
kzHqIqhzl3xJ5GqE0N2aMl
```

### 4. `figx plugin status` — WebSocket + manifest check in one

```
✓ figma-mcp-go WS up on 127.0.0.1:1994
✓ manifest: /Users/yu/Projects/figma-mcp-learning/plugins/figma-mcp-go/plugin/manifest.json
```

### 5. `figx plugin open` — the move that replaces 5 clicks

```
✓ Figma MCP Go dispatched
✓ WS 1994 listening
```

Under the hood: AppleScript clicks `Plugins → 개발 → Figma MCP Go` —
deterministic, locale-independent, works in both Design Mode and Dev
Mode.

### 6. `figx hermes check` — observability on

```
✓ Hermes Agent v0.8.0 (2026.4.8)
✓ Up to date
```

## The hybrid workflow this CLI was built for

The efficient path on a paid plan isn't REST or plugin — it's **both at
the same time**. figx makes that trivial.

```
   Your codebase                                   Figma Desktop
   ─────────────                                   ─────────────
   design tokens in code         (1) extract              │
     (e.g. pdp_pipeline/make_pdp.py) ─────────►  tokens.studio.json
                                                    tokens.dtcg.json
                                                    tokens.css
                                                          │
                                     (2) push via         ▼
                                         Tokens Studio    Variables
                                         plugin           (Pep / Cer modes)
                                                          │
                                     (3) figma-mcp-go     ▼
    figx plugin open  ──────────►    plugin              Styles
                                                          Components
                                                          Frames
                                     (4) figx publish     ▼
                                                          Library published

   figx hermes notify ──────────► Hermes ──► Telegram / Slack / Discord
```

| Step                        | Tool                                | What you type                        |
| --------------------------- | ----------------------------------- | ------------------------------------ |
| Extract tokens from code    | `figx` / `tools/extract_from_py.py` | `figx export tokens --fmt dtcg`      |
| Push to Variables (Pep/Cer) | Tokens Studio for Figma             | plugin UI, once                      |
| Create Styles / Components  | figma-mcp-go via MCP                | agent calls after `figx plugin open` |
| Publish library             | manual + polled                     | `figx publish`                       |
| Notify / audit              | Hermes webhook                      | automatic                            |

Enterprise users can substitute step 2 with `figx vars apply` (Variables
REST). Everyone else goes through Tokens Studio — same end state.

## Install

### One-shot bootstrap (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/MadKangYu/figx/main/bootstrap.sh | bash
```

The script installs `figx`, pulls the latest `figma-mcp-go` plugin
release, warms the MCP server, checks Accessibility permission, and
registers a Hermes webhook if Hermes is present.

### Manual

```bash
git clone https://github.com/MadKangYu/figx.git ~/scripts/figma-cli
ln -sf ~/scripts/figma-cli/figma ~/.local/bin/figx
figx doctor
```

> Naming note — the binary is **`figx`**, not `figma`. npm's `figma`
> binary would shadow us on most Node setups; this way you stay out of
> that fight.

## Quick start (5 minutes on a configured machine)

```bash
figx auth login                                   # paste PAT once
figx files find "https://www.figma.com/design/XXXXX/..."
figx plugin open                                  # launches Figma MCP Go
figx export tokens --fmt css  --out src/tokens.css
figx export tokens --fmt dtcg --out design/tokens.dtcg.json
# Tokens Studio plugin → Load from file system → tokens.studio.json → Push
figx publish                                      # guided manual publish
```

First-time users: `figx onboarding` walks the 7 preconditions
(account → app → PAT → file → plugin → apply → verify) one at a time.

## Command surface

| Command                                            | Purpose                                                          |
| -------------------------------------------------- | ---------------------------------------------------------------- |
| `figx version` / `figx doctor` / `figx onboarding` | environment + guided setup                                       |
| `figx auth {login,status,logout}`                  | Keychain-backed PAT management                                   |
| `figx files {current,set,find,list}`               | file-key discovery                                               |
| `figx vars {get,dump,apply}`                       | Variables read / write (write = Enterprise only)                 |
| `figx publish`                                     | guided manual publish, polls `/variables/published` up to 20 min |
| `figx devmode`                                     | file metadata + Dev Resources                                    |
| `figx export tokens --fmt {dtcg,css}`              | W3C DTCG / CSS custom properties                                 |
| `figx plugin {install,open,run,status}`            | figma-mcp-go plugin management                                   |
| `figx hermes {check,notify}`                       | Hermes version + ad-hoc webhook push                             |

Deeper reference: [`docs/CLI.md`](docs/CLI.md).

## How the pieces fit

```
figx (this CLI)
 ├── REST API  ────────────►  Figma cloud    (read everywhere, write on Enterprise)
 ├── AppleScript menu click ►  Figma Desktop (deterministic plugin launch)
 ├── npx @vkhanhqui/figma-mcp-go ►  MCP server on ws://127.0.0.1:1994
 │                                    └── figma-mcp-go Figma plugin connects here
 └── hermes webhook ──────►  Hermes Agent ── delivery (log | Telegram | Slack)
```

## Safety defaults

- PAT validated against `/v1/me` before storing.
- 401/403 stop **immediately** — no retrying auth failures.
- 429/5xx/network errors retry 5× with 2→4→8→16→32 s backoff.
- Uncaught errors flow through an `ERR` trap into both the local audit
  log and Hermes.
- Webhook delivery failure never propagates to the command's exit code.

## Plugin ecosystem

`figx` is designed around `figma-mcp-go` + `Tokens Studio for Figma`.
For related projects and IDE integrations — figma-mcp-bridge, figma
copilot, vscode-figma-mcp-helper, and more — see
[`docs/ESSENTIAL-PLUGINS.md`](docs/ESSENTIAL-PLUGINS.md).

## Docs

- [Setup](docs/SETUP.md) — from zero to first publish
- [Web setup](docs/WEB-SETUP.md) — accounts, PAT, browser-only steps
- [Figma Marketplace plugins](docs/FIGMA-MARKETPLACE.md) — what to install inside Figma after you have the app
- [Essential Figma plugins](docs/ESSENTIAL-PLUGINS.md) — curated GitHub-hosted plugins
- [Figma API reference](docs/FIGMA-API.md) — scopes, endpoints, rate limits
- [Integrations](docs/INTEGRATIONS.md) — Vercel, v0, Claude Code, Codex, OpenCode, Hermes
- [Automation](docs/AUTOMATION.md) — one-command docs sync
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common failure dictionary
- [Risk register](docs/RISKS-FIGMA-MCP-GO.md) — predicted failure modes of upstream
- [Is figx really a CLI?](docs/WHAT-IS-A-CLI.md) — yes, and why

## License

[MIT](LICENSE) © 2026 [KangYu (MadKangYu)](https://github.com/MadKangYu) · richardowen7212@gmail.com

## Credits

- [vkhanhqui/figma-mcp-go](https://github.com/vkhanhqui/figma-mcp-go) — the
  Figma Desktop plugin and MCP server this CLI drives.
- [Tokens Studio for Figma](https://tokens.studio) — the import-tokens
  plugin that makes the hybrid path work on any paid plan.
- [Hermes-Agent](https://github.com/anthropics/hermes-agent) — the
  messaging bridge every figx event lands in.
