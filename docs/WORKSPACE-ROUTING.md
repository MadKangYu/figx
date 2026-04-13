# Routing work to the paid workspace

> Figma plans are attached to **teams**, not users. A Professional /
> Organization / Enterprise subscription only unlocks features for
> files inside a team project belonging to that paid workspace. Files
> in your personal **Drafts** remain on the free tier even when you
> are paying elsewhere. figx makes the routing explicit.

## The failure mode

1. You pay for a Professional team.
2. You accidentally create the working Figma file in "Drafts".
3. Drafts files can't use multi-mode Variables, can't be published
   as a library, and Tokens Studio's `Push to Figma` fails with a
   plan-not-eligible error.

## The fix

Make sure the file lives under `Team → Project` on the paid workspace,
not under `Drafts`.

### Check programmatically

```bash
figx files verify
```

Output distinguishes:

- `✓ team-scoped file (id: …)` — good; on the paid workspace.
- `⚠ appears to be a personal Drafts file …` — move it before
  spending more time on it.

### Move a file from Drafts to the paid team

1. Open the file in Figma Desktop.
2. `File → Move to project…` → pick the team project.
3. Confirm. The file URL changes (new file-key) — re-run
   `figx files find` with the new URL.

### Launch the correct file in one shot

```bash
figx files open <file-key-or-url>
```

This:

1. Opens Figma Desktop directly to that file (`figma://file/<key>`).
2. Runs `figx plugin open` so figma-mcp-go is connected.
3. No manual navigation, no wondering which file the plugin is
   bound to.

### One-time setup per paid team

- Pin the paid team's starter projects in the Figma sidebar.
- Default all new files to be created inside `Team/Project`, not
  `Drafts`.
- Add yourself as a **Can edit** member on the team; guests can't
  mint Variables on Professional.

## How figx decides which file to work on

Resolution order (highest priority first):

1. `--file <key>` on the command line
2. `FIGMA_FILE_KEY` environment variable
3. `default_file_key` in `~/.config/figma/cli.toml`
4. Prompt (for `files list`)

Set once with:

```bash
figx files find "https://www.figma.com/design/<KEY>/<name>"
```

This writes to the config — every subsequent figx command targets that
file until you change it.

## Multi-workspace day-to-day

If you work across multiple paid teams:

- Create per-project configs: `figx project init` writes
  `.figx/project.toml` next to the code. The `figma_file_key`
  field in that file overrides the global default whenever the
  CLI is invoked from within that tree.
- Tag team-scoped webhooks: `hermes webhook subscribe figx-<team>`
  so notifications route by workspace.

## Why figx can't detect "free vs paid" more precisely

Figma REST exposes a file's team id but does not expose the team's
plan. The safe signal figx has is "has a team → likely paid, no team
→ definitely free Drafts". If you want stronger assurance:

- Test `POST /v1/files/:key/variables` in a scratch mode — an
  Enterprise plan will return `200`; anything else surfaces `403`.
- Use `figx vars get` — if it returns a 403 specifically citing
  `file_variables:read`, the account is sub-Enterprise; the file
  may still be Professional-eligible for the plugin path.

## Sanity checklist

- [ ] `figx files current` prints the expected key.
- [ ] `figx files verify` ends with the team checkmark.
- [ ] `figx plugin status` shows WS up and the right manifest.
- [ ] `figx plugin open` launches the plugin on that file.
- [ ] Tokens Studio's `Push to Figma` succeeds.

Any one of those failing surfaces which layer the routing broke.
