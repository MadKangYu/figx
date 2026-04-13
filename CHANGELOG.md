# Changelog

All notable changes to `figx` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com) and the project adheres to
[Semantic Versioning](https://semver.org).

## [0.1.0] — 2026-04-13

### Added

- Initial release.
- `figx auth {login|status|logout}` — PAT stored in macOS Keychain with
  `/v1/me` pre-validation.
- `figx files {current|set|find <url>|list}` — file-key discovery with URL
  parser for `figma.com/design/…`.
- `figx vars {get|dump|apply}` — Variables read (all plans) and write
  (Enterprise Full seat) via Figma REST `/v1/files/:key/variables`.
- `figx publish` — guided manual publish with 20-minute polling.
- `figx devmode` — file metadata + Dev Resources inspection.
- `figx export tokens --fmt {dtcg|css}` — token extraction.
- `figx plugin {install|open|run|status}` — figma-mcp-go plugin management.
  `open` uses a locale-independent AppleScript menu traversal (Plugins →
  Development → Figma MCP Go) to launch the plugin inside Figma Desktop.
- `figx hermes {check|notify}` — Hermes-Agent webhook bridge with local
  log fallback.
- `figx onboarding` — 7-step interactive wizard (account → app → PAT →
  file → plugin → apply → verify).
- `figx doctor` — dependency + credential self-check.
- `tools/extract_from_py.py` — Python AST parser that converts a project's
  token constants into `tokens.dtcg.json`, `tokens.css`, and
  `tokens.studio.json` (Tokens Studio for Figma plugin format).
- Failure policy: 401/403 stop immediately, 429/5xx retried with exponential
  backoff (5 attempts), uncaught errors surfaced through an `ERR` trap and
  pushed to Hermes.
