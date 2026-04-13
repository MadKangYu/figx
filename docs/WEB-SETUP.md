# Web side — accounts & one-time browser steps

> Things you do in a browser (once). Everything else runs in the
> terminal via figx.

## Browser

Any modern browser works. macOS Safari is fine; no install needed.
Chrome is only required if you prefer it — figx doesn't care.

## Accounts

### Required

| Service                            | Why                                                                    | Where                                                 |
| ---------------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------- |
| **Figma**                          | the tool figx drives                                                   | https://www.figma.com                                 |
| **Figma Professional (or higher)** | multi-mode Variables — Pep/Cer SKU transition needs it                 | Figma → Settings → Plans → Upgrade                    |
| **GitHub**                         | `gh` downloads the `figma-mcp-go` plugin release during `bootstrap.sh` | https://github.com (then `gh auth login` in terminal) |

### Optional

| Service                           | Adds                                    | When to add                              |
| --------------------------------- | --------------------------------------- | ---------------------------------------- |
| **Telegram Bot** (`@BotFather`)   | push figx events to Telegram via Hermes | if you want phone alerts on publish      |
| **Slack app**                     | same, for Slack                         | team channels                            |
| **v0.dev**                        | convert Figma Dev Mode links to React   | if your code generation leans on v0      |
| **Vercel**                        | auto-publish `tokens.css` builds        | if the design tokens land in a live site |
| **Claude Anthropic / OpenAI API** | Claude Code / Codex direct access       | already configured in most setups        |

## One-time browser actions

### 1. Create a Figma Personal Access Token

1. https://www.figma.com/settings
2. Left sidebar → **Security**
3. **Personal access tokens → Generate new token**
4. Name: `amplen-cli` (or any label)
5. Expiration: **90 days** (Figma's cap; figx reminds you when it's near)
6. Scopes to check — what figx uses:
   - 사용자 / User → 읽기
   - 파일 / File → 내용, 메타데이터, 버전 모두 읽기
   - 디자인 시스템 / Design system → 전부 읽기
   - 개발 / Development → 개발 리소스 읽기
   - (Enterprise) Variables 읽기 + 쓰기
7. **Generate token** → copy the `figd_…` string right away.
8. In terminal: `figx auth login` → paste → Enter.

### 2. Copy your working file's link

1. Open the Figma file in Desktop.
2. **Share → Copy link**.
3. `figx files find "<pasted URL>"` saves the file-key to `~/.config/figma/cli.toml`.

### 3. (Optional) Register a Telegram bot for Hermes

1. Open `@BotFather` in Telegram.
2. `/newbot` → name → username.
3. Copy the token.
4. `hermes gateway setup` and paste the token when prompted.
5. Switch the figma-tokens webhook delivery:
   ```bash
   hermes webhook rm figma-tokens
   hermes webhook subscribe figma-tokens \
     --deliver telegram --deliver-chat-id <YOUR_CHAT_ID>
   ```

## After those three browser tasks

Everything else — plugin install, MCP registration, token extraction,
library publish, notifications — runs from terminal. No more clicks in
the web UI.

## Related docs

- [`SETUP.md`](SETUP.md) — full terminal walkthrough
- [`FIGMA-MARKETPLACE.md`](FIGMA-MARKETPLACE.md) — Community plugins to install inside Figma
- [`INTEGRATIONS.md`](INTEGRATIONS.md) — Vercel, v0, Claude Code, Codex, OpenCode, Hermes
