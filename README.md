# figx — a pragmatic Figma command line

<p align="left">
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="platform" src="https://img.shields.io/badge/platform-macOS-lightgrey">
  <img alt="shell" src="https://img.shields.io/badge/shell-bash-89e051">
  <a href="CHANGELOG.md"><img alt="version" src="https://img.shields.io/badge/version-0.1.0-orange"></a>
</p>

`figx` is a single-file bash CLI for working with Figma from the terminal.
It wraps the Figma REST API, drives the `figma-mcp-go` Figma Desktop
plugin via AppleScript, pushes events to
[Hermes-Agent](https://github.com/anthropics/hermes-agent), and keeps
Personal Access Tokens in the macOS Keychain.

**Why:** shipping design tokens through Figma shouldn't require a desktop
plugin wizard every time. `figx` makes the happy path — "read the Python
constants in my repo and turn them into a Figma variables collection" —
a single command, and degrades gracefully when your plan doesn't unlock
the Variables REST API.

---

## Features

- **One-shot token publish.** `figx export tokens` emits W3C DTCG JSON,
  CSS custom properties, and Tokens Studio for Figma `tokens.studio.json`
  in one pass — usable on every Figma plan.
- **Figma Desktop automation without a plugin wizard.** `figx plugin open`
  clicks **Plugins → Development → Figma MCP Go** through a deterministic
  AppleScript menu traversal (locale-independent, Quick Actions-free).
- **Safe credential handling.** PATs are validated against `/v1/me`
  before being stored, kept in macOS Keychain, and fall back to a
  `FIGMA_PAT` env var in CI.
- **Structured retries.** 401/403 stop immediately; 429/5xx get five
  exponential retries; uncaught errors flow through an `ERR` trap into
  both the local audit log and Hermes.
- **Interactive onboarding.** `figx onboarding` walks a new user through
  the 7 steps that actually matter (account → app → PAT → file → plugin →
  apply → verify), instead of leaving them to the docs.
- **Hermes-native.** Every command emits an event to the `figma-tokens`
  Hermes webhook; if Hermes is down, events hit `~/.local/state/figma-cli/events.log`
  and the command still succeeds.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/MadKangYu/figx/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/MadKangYu/figx.git ~/scripts/figma-cli
ln -sf ~/scripts/figma-cli/figma ~/.local/bin/figx
figx version
```

Requirements: macOS, `curl`, `jq`, `python3`, `security`, and `gh` on
`PATH`. `figx doctor` confirms them for you.

> Heads-up: the binary is named `figx` (not `figma`) because npm's
> `figma` CLI shadows `/usr/local/bin/figma` on most Node setups.

## Quick start

```bash
figx onboarding                           # step-by-step wizard
figx auth login                           # paste PAT, stored in Keychain
figx files find "https://www.figma.com/design/XXXXX/..."
figx vars get | jq '.meta.variableCollections[].name'
figx export tokens --fmt css --out tokens.css
figx plugin open                          # launches figma-mcp-go inside Figma Desktop
```

## Commands

| Command                                            | Purpose                                                              |
| -------------------------------------------------- | -------------------------------------------------------------------- |
| `figx version` / `figx doctor` / `figx onboarding` | environment + guided setup                                           |
| `figx auth {login,status,logout}`                  | Keychain-backed PAT management                                       |
| `figx files {current,set,find,list}`               | file-key discovery                                                   |
| `figx vars {get,dump,apply}`                       | Variables CRUD (write requires Enterprise)                           |
| `figx publish`                                     | guided manual publish, polls `/variables/published` for up to 20 min |
| `figx devmode`                                     | file metadata + Dev Resources                                        |
| `figx export tokens --fmt {dtcg,css}`              | W3C DTCG / CSS custom properties                                     |
| `figx plugin {install,open,run,status}`            | manage the figma-mcp-go plugin                                       |
| `figx hermes {check,notify}`                       | Hermes version + ad-hoc webhook push                                 |

Full reference: [`docs/CLI.md`](docs/CLI.md).

## Design tokens bridge

`tools/extract_from_py.py` parses the top-level `PAD`, `SIZE`, `LH`,
`PALETTE`, `HL`, and `COLORS` constants of a Python design-pipeline file
(via `ast.literal_eval`, no execution) and produces three drop-in
artifacts:

| File                 | Target                                                                          |
| -------------------- | ------------------------------------------------------------------------------- |
| `tokens.dtcg.json`   | W3C Design Tokens Community Group — a standard many tools read                  |
| `tokens.css`         | CSS custom properties with a `[data-sku='cer']` SKU toggle                      |
| `tokens.studio.json` | Tokens Studio for Figma plugin — `base / sku/pep / sku/cer` sets with `$themes` |

Tokens Studio is the fallback path when you're not on Figma Enterprise:
import `tokens.studio.json`, activate a theme, hit **Push to Figma** and
the variables appear in the file's Local Variables panel.

## Auth and safety

- PAT scopes map to
  [Figma's 2025-04 split](https://developers.figma.com/docs/rest-api/changelog/):
  `file_content:read`, `file_metadata:read`, `file_dev_resources:read` —
  plus `file_variables:read/write` if your workspace exposes them.
- PATs have a **90-day maximum** (April 2025 policy change); `figx auth
login` records the issue time for you.
- Keys never hit disk in plaintext outside the Keychain-backed entry.
- All requests go through `lib/api.sh`; every non-2xx is either stopped
  (401/403) or retried with exponential backoff (429/5xx).

## Hermes integration

```
figx                                                     Hermes Agent
 └── lib/hermes.sh ──► POST /webhooks/figma-tokens ──► delivery (log | telegram | slack | …)
                          │
                          └── on failure, append to ~/.local/state/figma-cli/events.log
```

Create the webhook once:

```bash
hermes webhook subscribe figma-tokens \
  --deliver log \
  --prompt "figx: {message}"
```

Switch it to Telegram at any time:

```bash
hermes webhook rm figma-tokens
hermes webhook subscribe figma-tokens \
  --deliver telegram --deliver-chat-id <CHAT_ID>
```

## Troubleshooting

| Symptom                             | Cause                                                                      | Fix                                                        |
| ----------------------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `unknown command 'auth'`            | npm `figma` CLI shadows your shim                                          | use `figx`, not `figma`                                    |
| 403 `file_variables:read`           | plan lacks Variables API (non-Enterprise)                                  | use Tokens Studio instead; see `tokens.studio.json` output |
| `plugin not connected`              | the Figma MCP Go plugin is not running in Figma Desktop                    | `figx plugin open`                                         |
| `Accessibility permission required` | Terminal app isn't in System Settings → Privacy & Security → Accessibility | enable it, re-run `figx plugin open`                       |
| `429 rate limited`                  | Figma API cap                                                              | CLI retries with backoff; reduce concurrency if persistent |

Long-form failure dictionary: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Repository layout

```
figma-cli/
├── figma             # single entrypoint — routes subcommands
├── lib/
│   ├── api.sh        # curl + retry + HTTP policy
│   ├── keychain.sh   # macOS Keychain wrapper
│   ├── hermes.sh     # Hermes webhook adapter, local-log fallback
│   ├── files.sh      # file-key parsing / config persistence
│   ├── vars.sh       # /variables read + write
│   └── onboarding.sh # interactive 7-step wizard
├── tools/
│   ├── extract_from_py.py       # Python AST → tokens.{dtcg,css,studio}.json
│   ├── auto-import-plugin.applescript
│   └── auto-run-plugin.applescript
├── docs/             # long-form reference (CLI, tokens, troubleshooting)
├── install.sh        # one-liner installer
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

## License

[MIT](LICENSE) © 2026 KangYu.

## Credits

- [`vkhanhqui/figma-mcp-go`](https://github.com/vkhanhqui/figma-mcp-go)
  — the Figma Desktop development plugin and MCP server this CLI drives.
- [Tokens Studio for Figma](https://tokens.studio) — the no-Enterprise
  path for importing variables.
- Figma REST API docs — https://developers.figma.com/docs/rest-api/
