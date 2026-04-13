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
