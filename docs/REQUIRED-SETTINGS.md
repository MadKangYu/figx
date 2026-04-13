# Required Figma settings — MECE checklist

> Settings you must confirm before figx / Tokens Studio / figma-mcp-go
> will behave predictably. Grouped MECE (Mutually Exclusive, Collectively
> Exhaustive) — each item belongs to exactly one bucket, and all buckets
> together cover the setup surface.

Sources: help.figma.com, developers.figma.com, direct UI verification.

## A. Account

| #   | Setting               | Where                     | Required value                              | Why                                      |
| --- | --------------------- | ------------------------- | ------------------------------------------- | ---------------------------------------- |
| A1  | Plan                  | Settings → Plans          | **Professional or higher**                  | Multi-mode Variables, library publishing |
| A2  | Account email         | Settings → Profile        | matches your work/team email                | Team seat assignment                     |
| A3  | Two-factor auth       | Settings → Security       | **Enabled**                                 | Protects PAT creation                    |
| A4  | Personal Access Token | Settings → Security → PAT | **Issued, ≤90 days** with scopes figx needs | API auth for figx                        |

## B. Team

| #   | Setting                   | Where                       | Required value                                     | Why                              |
| --- | ------------------------- | --------------------------- | -------------------------------------------------- | -------------------------------- |
| B1  | Team workspace            | Home → team dropdown        | Paid team (e.g., **MADSTAMP / AMPLE:N**) is active | Scopes all file features         |
| B2  | Team members / seats      | Team → Members              | You hold an **Editor seat** (not Viewer/Guest)     | Variables write, library publish |
| B3  | Team library settings     | Team → Settings → Libraries | **Libraries enabled**                              | Cross-file Variables sharing     |
| B4  | Branching (Organization+) | Team → Settings → Branching | Enabled if available                               | Safe non-trivial edits           |

## C. Project

| #   | Setting                  | Where                      | Required value                                 | Why                              |
| --- | ------------------------ | -------------------------- | ---------------------------------------------- | -------------------------------- |
| C1  | File location            | Sidebar                    | File **is in a team Project**, NOT in `Drafts` | Drafts = free-tier features only |
| C2  | Project sharing          | Project → Share            | At least **Can edit** for you                  | Variables apply                  |
| C3  | Project id saved in figx | `~/.config/figma/cli.toml` | `default_project_id` set                       | figx looks up files by name      |

## D. File

| #   | Setting                | Where                       | Required value         | Why                             |
| --- | ---------------------- | --------------------------- | ---------------------- | ------------------------------- |
| D1  | File role              | File → Share                | **Owner or Editor**    | Apply Variables                 |
| D2  | Library publish        | Assets → Publish            | Enabled when ready     | Downstream files consume tokens |
| D3  | Version history        | File → Show version history | Retained               | Rollback on bad publish         |
| D4  | file_key saved in figx | cli.toml                    | `default_file_key` set | All figx commands target it     |

## E. Desktop app

| #   | Setting                 | Where                     | Required value                                | Why                             |
| --- | ----------------------- | ------------------------- | --------------------------------------------- | ------------------------------- |
| E1  | Figma Desktop installed | `/Applications/Figma.app` | Current version                               | Plugins require Desktop         |
| E2  | Desktop language        | Figma → Preferences       | Any supported; figx detects EN + KO + JA + ZH | Menu name variance              |
| E3  | Dev Mode toggle         | top-right `</>`           | Either state OK — figx auto-detects           | Plugin menus differ subtly      |
| E4  | Hot-reload plugin       | Plugins → Development     | **Off** during token publish                  | Prevents mid-operation restarts |

## F. Plugins (inside Figma)

| #   | Plugin                        | Status             | Why                        |
| --- | ----------------------------- | ------------------ | -------------------------- |
| F1  | **Tokens Studio for Figma**   | Saved              | Variables push path        |
| F2  | **Figma MCP Go** (Dev plugin) | Imported + running | Agent-driven editing       |
| F3  | **Contrast**                  | Saved              | Accessibility gate         |
| F4  | Variables plugins (optional)  | Saved if needed    | See `ESSENTIAL-PLUGINS.md` |

## G. macOS / environment

| #   | Item                               | State                              |
| --- | ---------------------------------- | ---------------------------------- |
| G1  | Accessibility permission           | Terminal enabled (System Settings) |
| G2  | Automation (Figma + System Events) | Enabled                            |
| G3  | Keychain unlocked                  | yes                                |
| G4  | Outbound reachable                 | `api.figma.com` green              |
| G5  | Loopback 127.0.0.1:1994            | reachable (plugin on)              |

Verify with:

```bash
figx permissions
figx doctor
figx plugin status
```

## H. Agents / integrations

| #   | Config          | Where                              | Required                     |
| --- | --------------- | ---------------------------------- | ---------------------------- |
| H1  | Claude Code MCP | `~/.mcp.json`                      | `figma-mcp-go` entry         |
| H2  | Codex MCP       | `~/.codex/config.toml`             | `[mcp_servers.figma-mcp-go]` |
| H3  | OpenCode MCP    | `~/.config/opencode/opencode.json` | `mcp.figma-mcp-go`           |
| H4  | Hermes webhook  | `hermes webhook list`              | `figma-tokens`               |

`figx plugin register-mcp all` sets H1–H3 in one shot.

## Verification script

```bash
figx doctor            # G-group
figx permissions       # G-group detail
figx hermes check      # H4
figx plugin status     # E3, F2
figx auth status       # A4
figx files current     # D4
figx files team current   # B1
figx files project current # C3
figx files mode detect    # E3
figx files verify      # C1, D1
```

If any of those return an error, map to the row above and fix that row
before moving on.

## What figx automates

| Row   | Automated by                                        |
| ----- | --------------------------------------------------- |
| A4    | `figx auth login` (Keychain + /v1/me validation)    |
| B1    | `figx files team open`                              |
| C3    | `figx files project set <url>`                      |
| D4    | `figx files find <url>` / `files set <key>`         |
| E3    | `figx files mode {detect,set}`                      |
| F2    | `figx plugin install` (AppleScript manifest import) |
| G1–G5 | `figx permissions`                                  |
| H1–H4 | `figx plugin register-mcp all` / `bootstrap.sh`     |

Rows A1, A2, A3, B2, B3, B4, C1 (initial move), D1, D2, E1, E4, F1, F3 are
human decisions — the CLI surfaces state but won't change them silently.

## The one-paragraph story

Open Figma Desktop in the **paid team** workspace. Move the file you want
to work on out of **Drafts** and into a **team project**. Install
**Tokens Studio**, let figx import **Figma MCP Go**. Grant macOS
Accessibility + Automation permissions. Issue a **PAT** valid for 90 days
and hand it to `figx auth login`. Register the MCP server into your
agents with `figx plugin register-mcp all`. After that every
automation step is a one-liner.
