# Setup Guide

> End-to-end setup from a clean macOS machine to a working `figx plugin open`.

## 0. Prerequisites

| Requirement                          | How to check / install                                                                          |
| ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| macOS 14+                            | `sw_vers -productVersion`                                                                       |
| Figma Desktop                        | `/Applications/Figma.app` — download at https://www.figma.com/downloads                         |
| Figma Professional plan (or higher)  | https://www.figma.com/settings → Plans. Multi-mode Variables (Pep/Cer SKU) needs Professional+. |
| Node 18+                             | `node --version` — `brew install node` if missing                                               |
| `curl`, `jq`, `gh`, `git`, `python3` | all macOS standard / `brew install jq gh`                                                       |

## 1. One-shot bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/MadKangYu/figx/main/bootstrap.sh | bash
```

That single command:

1. Verifies `curl`, `jq`, `gh`, `git`, `python3`, `security`, `nc`, `osascript`.
2. Installs `figx` into `~/.local/share/figx` with a symlink at `~/.local/bin/figx`.
3. Downloads the `figma-mcp-go` plugin zip from
   [vkhanhqui/figma-mcp-go](https://github.com/vkhanhqui/figma-mcp-go)
   (latest release) and extracts to
   `~/Projects/figma-mcp-learning/plugins/figma-mcp-go/`.
4. Warms up the npm MCP server (`npx @vkhanhqui/figma-mcp-go`) so first
   launch is instant.
5. Verifies macOS Accessibility permission for the terminal (required
   for `figx plugin open`).
6. Registers a Hermes `figma-tokens` webhook if Hermes is installed.
7. Runs `figx doctor`.

## 2. One-time: import the plugin into Figma Desktop

This is the **only** step `figx` cannot automate — Figma requires a manual
`Import plugin from manifest` the first time. After that, `figx plugin
open` relaunches it via a menu-click AppleScript.

1. Open Figma Desktop.
2. Open any file.
3. Menu: `Plugins → Development → 매니페스트에서 플러그인 가져오기…`
   (English: `Import plugin from manifest…`)
4. Pick the manifest saved by bootstrap at:
   ```
   ~/Projects/figma-mcp-learning/plugins/figma-mcp-go/plugin/manifest.json
   ```
5. You should see **Figma MCP Go** under `Plugins → Development`.

## 3. Authenticate

```bash
figx auth login
```

Paste a Figma Personal Access Token ([generate here](https://www.figma.com/settings)
— Security → Personal access tokens). Scopes to check:

- File content — read
- File metadata — read
- Dev resources — read
- **Variables — read + write** (only visible if your plan exposes them;
  Enterprise-only in 2026)

The token is validated against `/v1/me` and stored in the macOS Keychain
(`service=figma-cli, account=default`). If your terminal can't reach
Keychain (e.g., SSH session), set `FIGMA_PAT` instead.

## 4. Link your working file

```bash
figx files find "https://www.figma.com/design/XXXXX/my-file"
figx files current    # should print the file-key
```

Or by environment variable:

```bash
export FIGMA_FILE_KEY=XXXXX
```

## 5. Launch the plugin (deterministic)

```bash
figx plugin open
```

Under the hood this clicks `Plugins → 개발 → Figma MCP Go` via
AppleScript `System Events` (not via the fragile Quick Actions command
palette). It verifies the WebSocket on `127.0.0.1:1994` afterward.

If it fails with "Accessibility permission required", add your terminal
in System Settings → Privacy & Security → Accessibility.

## 6. Interactive onboarding

If you prefer the guided path:

```bash
figx onboarding
```

A 7-step wizard that verifies every precondition (plan, app, PAT, file,
plugin, apply, verify) and pauses at each step for confirmation.

## 7. Troubleshooting

See [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
