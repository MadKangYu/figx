# Integrations

How figx plays with adjacent tools you likely already use.

## Vercel

**Deploying a site that consumes figx-generated tokens:**

1. `figx export tokens --fmt css --out src/app/tokens.css`
2. Commit, push. Vercel auto-builds.
3. Add `FIGMA_PAT` to Vercel project env (Settings → Environment Variables).
4. For nightly token refresh, add a Vercel Cron:
   ```json
   { "crons": [{ "path": "/api/refresh-tokens", "schedule": "0 3 * * *" }] }
   ```
5. The handler exec's `figx vars dump` → diff → auto-PR.

**Preview deploys per token change:** use the `LIBRARY_PUBLISH` Figma
webhook → Vercel deploy hook URL (Settings → Git → Deploy Hooks) to
kick off a preview every time the design team publishes.

## v0.dev

**Seed v0 with your real design tokens:**

1. `figx export tokens --fmt css` produces a single `tokens.css`.
2. Upload it (or drop into the project) when starting a v0 chat.
3. v0 will honor `--color-sku-primary`, `--spacing-xl`, etc.

**Figma → v0 flow:**

1. Copy a Figma Dev Mode link (`&mode=dev`).
2. In v0, paste + ask for an implementation.
3. v0 uses the official Figma MCP (not figma-mcp-go) to read the node.
4. If it needs values, point at your `tokens.css` from step 1.

**v0 SDK from figx scripts:**

```bash
curl -sS https://api.v0.dev/v1/generate \
  -H "Authorization: Bearer $V0_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg prompt "Build a button using $(cat tokens.css | head -20)" '{prompt: $prompt}')"
```

## Claude Code

Already covered — `figx plugin register-mcp claude` writes to
`~/.mcp.json`. Restart Claude Code.

## Codex CLI

`figx plugin register-mcp codex` writes a `[mcp_servers.figma-mcp-go]`
block to `~/.codex/config.toml`.

## OpenCode (oh-my-openagent)

`figx plugin register-mcp opencode` writes `mcp.figma-mcp-go` to
`~/.config/opencode/opencode.json`.

## Cursor

Same `~/.mcp.json` as Claude Code.

## Register everywhere at once

```bash
figx plugin register-mcp all
```

## Chrome DevTools Protocol (CDP) — OpenChrome MCP

Some design references sit behind logins, SPAs, or ephemeral state
that the official Figma + v0 pipelines can't read directly. CDP
closes the gap: a real Chromium instance you control from the
terminal or from an agent, with full cookie / session awareness.

### Setup (once)

- A dedicated Chrome profile for automation lives at
  `~/.chrome-cdp/primary` with the CDP endpoint on `127.0.0.1:9223`.
- The **OpenChrome MCP** server (`mcp__openchrome__*` tools) is the
  canonical programmatic interface — navigate, read_page, inspect,
  fill_form, take_screenshot, etc.
- Status file: `~/.chrome-cdp/active-session.json` (session truth).

### Patterns that pair with figx

1. **Competitor detail-page harvesting.**
   Agent opens a paid / login-walled product page via OpenChrome,
   `read_page` to pull the rendered DOM, then
   `generate_figma_design` (official Figma MCP) to seed a Figma
   layout.

2. **Design reference ingestion.**
   `mcp__openchrome__navigate` → load a reference site → `inspect`
   and `get_screenshot` → feed the screenshot into figma-mcp-go's
   `import_image` on the target frame. See also
   [`IMAGE-UPLOAD.md`](IMAGE-UPLOAD.md) for size / format pre-prep.

3. **OAuth / PAT flows.**
   When a service doesn't expose a headless auth path, OpenChrome
   drives the browser click-path and `storage` / `cookies` tools
   capture the resulting session. figx never sees the password —
   only the PAT that Keychain ends up with.

4. **Dev-Mode screenshot diffs.**
   Open the same Figma Dev-Mode URL at two timestamps; diff the
   screenshots to spot unintended drift before a publish.

### When to reach for CDP vs the official Figma MCP

| Task                                 | Tool                                                 |
| ------------------------------------ | ---------------------------------------------------- |
| Read a public Figma file             | `mcp__figma__get_design_context`                     |
| Generate code from Figma             | official Figma MCP + v0                              |
| Load a login-walled page             | OpenChrome                                           |
| Interact with an SPA (wait for JS)   | OpenChrome (`wait_for`, `javascript_tool`)           |
| Upload a CDP-captured image to Figma | figma-mcp-go `import_image` after `figx images prep` |

### Safety

- CDP gives full browser control — treat the `~/.chrome-cdp/primary`
  profile as trusted, not a scratch pad. Don't install extensions
  you wouldn't run on your main browser.
- Session state lives in that profile; rotate cookies the same way
  you rotate PATs (every 90 days minimum).
- `figx permissions` surfaces loopback reachability; if the CDP
  endpoint can't bind to 9223, networking is the first check.

## Supabase

Optional but handy for teams without Enterprise Figma. The pattern:

- Keep the **authoritative tokens** in a Supabase table
  (`tokens (id, key, value, type, mode)`).
- A Supabase Edge Function serves them as both JSON (for CI) and
  CSS (for runtime theming).
- figx `export` feeds Supabase; Tokens Studio reads from Supabase
  through its JSON URL support.

```sql
create table tokens (
  id bigserial primary key,
  key text not null,
  mode text not null default 'default',
  type text not null,
  value jsonb not null,
  updated_at timestamptz default now(),
  unique (key, mode)
);
```

Push from figx:

```bash
figx export tokens --fmt dtcg --out /tmp/tokens.dtcg.json
psql "$SUPABASE_DB_URL" -c "\copy tokens(key, mode, type, value) from /tmp/tokens.csv csv"
```

Supabase MCP is already set up in `~/.codex/config.toml` here
(`mcp_servers.supabase`), so any agent can read/write the table
directly.

## Hermes-Agent

Every figx command can push events. Register a webhook once, then use
it from figx or any other tool:

```bash
hermes webhook subscribe figma-tokens --deliver log
# Switch to Telegram later:
hermes webhook rm figma-tokens
hermes webhook subscribe figma-tokens --deliver telegram --deliver-chat-id <CHAT_ID>
```

## Hooks you can add

- On `LIBRARY_PUBLISH` → `figx export tokens --fmt css --out …` → git commit
- On nightly cron (`0 3 * * *`) → `figx doctor && figx hermes check`
- Pre-commit in your design repo → `figx export tokens --fmt dtcg --out tokens.dtcg.json`
