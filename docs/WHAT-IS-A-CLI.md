# Is `figx` really a CLI?

Short answer: **yes**, and on purpose.

## Definition check

A CLI (command-line interface) is a program invoked from a shell with
arguments, optionally reading from stdin and writing to stdout/stderr.
By that bar `figx` qualifies — it is a single executable you call with
subcommands (`figx vars apply file.json`), supports environment
variables and a config file, returns meaningful exit codes, and never
opens a GUI window of its own.

## Why the confusion is fair

Some of what `figx` does touches a desktop app (Figma). Specifically:

- `figx plugin open` tells Figma Desktop to activate a plugin via
  AppleScript.
- The subsequent work (Push to Figma, Publish Library) requires the
  Figma Desktop UI to be visible to the user.

That's still a CLI. The pattern is common: `git push origin main`
triggers network work; `git commit` opens your editor; neither stops
`git` from being a CLI. Similarly `figx` drives an external app but
stays terminal-driven.

## What's strictly terminal-only

- `figx version`, `doctor`, `onboarding` (text UI)
- `figx auth {login, status, logout}`
- `figx files {current, set, find, list}`
- `figx vars {get, dump}` (write uses REST only; Enterprise)
- `figx export tokens …`
- `figx hermes {check, notify}`
- `figx plugin {install, status}`

## What requires the Figma Desktop app

- `figx plugin open` — clicks `Plugins → Development → Figma MCP Go`
- `figx plugin run` — runs the MCP server in the foreground; the
  plugin in Figma connects back to it
- Any subsequent MCP call (`mcp__figma-mcp-go__*`) from Claude Code
  or another agent

## Comparison

| Tool     | Category | Notes                                |
| -------- | -------- | ------------------------------------ |
| `git`    | CLI      | sometimes opens $EDITOR              |
| `gh`     | CLI      | sometimes opens browser              |
| `docker` | CLI      | talks to a daemon process            |
| `vercel` | CLI      | triggers cloud builds                |
| `figx`   | CLI      | drives Figma Desktop via AppleScript |

Calling `figx` a CLI matches the shape of every tool above.
