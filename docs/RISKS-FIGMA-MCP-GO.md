# Risk register — figma-mcp-go

> Predicted failure modes of the upstream dependency
> [`vkhanhqui/figma-mcp-go`](https://github.com/vkhanhqui/figma-mcp-go).
> figx leans heavily on this project; if it degrades, figx's plugin
> path degrades with it. This doc keeps the risks visible and
> documents figx's mitigation for each.

Severity rubric: 🔴 blocks core use · 🟡 workaround needed · 🟢 minor

## Dependency / supply chain

### 🔴 npm package removal or hijack

`npx -y @vkhanhqui/figma-mcp-go@latest` fetches every session.
Unpublish, namespace takeover, or a malicious publish would immediately
hit users.

- Mitigation now: we pin `@latest` in bootstrap, but switching to a
  SHA-pinned version is safer (`@0.1.3` at minimum).
- Planned: cache the tarball locally under `~/.local/share/figx/vendor/`
  and fall back to it if `npx` fails.

### 🟡 `@latest` version drift

Upstream pushes a breaking change, every figx user sees it.

- Mitigation: track upstream in `CHANGELOG.md`; pin in the next figx
  release.

### 🟡 Plugin release deletion

`gh release download` in `bootstrap.sh` pulls `plugin.zip` by tag.
If upstream deletes the release, fresh installs fail.

- Mitigation now: bootstrap tolerates missing release and warns.
- Planned: vendor the `plugin.zip` at a known figx release SHA and
  ship it from our repo.

### 🔴 Single-maintainer abandonment

One person owns both the plugin and the MCP server.

- Mitigation: fork policy — if no activity for 90 days we fork to
  `MadKangYu/figma-mcp-go-fork` and redirect bootstrap URLs.

## Figma Desktop / Plugin API

### 🔴 Plugin manifest `api: "1.0.0"` deprecation

Figma supports an evolving plugin API; old `api` versions eventually
expire.

- Mitigation: manifest is small, we can bump it to whatever the
  upstream bumps to. Pinned to upstream releases.

### 🟡 Development plugin policy tightening

Figma could restrict sideloaded dev plugins (require signing, a
developer account, or marketplace submission).

- Mitigation: submit figma-mcp-go to the Figma Community marketplace
  as a backup distribution channel.

### 🟡 "Hot reload plugin" causing mid-operation restarts

The `Plugins → Development → 핫 리로드 플러그인` checkbox, if on,
reloads the plugin whenever its code changes — mid-POST inconsistency.

- Mitigation: documented as off for figx operations; `figx doctor`
  could query plugin state in a future release.

### 🟢 Menu locale drift

Figma may add locales we haven't enumerated (e.g. es / pt / vi /
ru variants of "Plugins").

- Mitigation: `figx plugin open` already tries EN/KO/JA/ZH. Extend
  `pluginMenuNames` / `devMenuNames` in `figma` if needed.

### 🟡 Profile reset wipes Development plugin list

Figma profile v39 stores the imported manifest path. A forced reset
loses it.

- Mitigation: `figx plugin install` re-runs the AppleScript import
  sequence without a full bootstrap.

## Runtime / networking

### 🔴 Port 1994 conflict

Hard-coded on the plugin side. Another local service or an old
figma-mcp-go process holding the port prevents handshake.

- Mitigation: `figx plugin status` + manual `lsof -i :1994`; we can
  parameterize when upstream supports it.

### 🟡 Corporate firewall blocks loopback

Some managed Macs block `127.0.0.1:1994` via network extensions.

- Mitigation: surfaced in `figx permissions` (outbound + loopback
  checks).

### 🟡 Concurrent WebSocket clients

Claude Code + Codex + OpenCode all connecting to the single plugin
WS simultaneously — the plugin may only serve one client cleanly.

- Mitigation: document "one agent at a time"; run `figx plugin
status` before switching tools.

## Response size

### 🟡 Tool results over 20 KB

`get_design_context` on large Figma files can return >20 KB and get
truncated by the MCP client.

- Mitigation: use node-scoped requests (`get_node`), not
  whole-document dumps. Documented in
  `/Users/yu/Projects/figma-mcp-learning/CLAUDE.md` (section 4
  "페이지 전체 변환 시 섹션별 순서").

## Trust / verification

### 🟡 Plugin asset not integrity-verified

`bootstrap.sh` trusts whatever `gh release download` gives us. If
GitHub were MITM'd (unlikely but) or the release asset swapped, we
install it anyway.

- Mitigation: planned — record SHA256 of the pinned `plugin.zip` in
  `bootstrap.sh` and verify before extracting.

### 🟢 npm supply-chain tooling

`npx` runs any postinstall scripts. The MCP server is JS, not
sandboxed.

- Mitigation: read `node_modules/@vkhanhqui/figma-mcp-go` once, pin
  the version, cache the tarball.

## Platform lock-in

### 🟡 macOS-only

`figx plugin open` uses AppleScript System Events. Linux / Windows
users have no menu automation.

- Mitigation: on Linux, `xdotool`-based variant is feasible. Out of
  scope for v0.1.0; planned for v0.2.

## What figx already does to contain these

- `lib/api.sh`: retries 429/5xx, stops on 401/403. Any upstream API
  drift surfaces loudly, not silently.
- `lib/hermes.sh`: pushes every event — problems are observable
  within minutes, not on next user complaint.
- `figx doctor` + `figx permissions` + `figx plugin status`: triage
  surface for 90% of the listed issues.
- Independent path: if figma-mcp-go fails completely, `figx export
tokens --fmt tokens.studio.json` still produces a file the Tokens
  Studio plugin can consume. No single point of failure for the
  token publish pipeline.

## Next actions on this list

| Priority | Work                             | Where                           |
| -------- | -------------------------------- | ------------------------------- |
| 🔴       | Pin upstream version             | `bootstrap.sh`, `lib/hermes.sh` |
| 🔴       | Vendor `plugin.zip` at known SHA | `assets/vendor/`                |
| 🟡       | SHA256 verify on plugin download | `bootstrap.sh`                  |
| 🟡       | Fork plan if abandoned           | this doc, renewed quarterly     |
| 🟡       | Extended locale menu names       | `figma` script                  |
| 🟢       | Linux / Windows variant          | v0.2 roadmap                    |
