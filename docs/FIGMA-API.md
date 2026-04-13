# Figma API — working reference

> Distilled from the official Figma developer docs. Use this page to
> decide which endpoint / scope / auth method to reach for from inside
> figx or an agent chain. Sources linked at the bottom.

## Auth methods

| Method                      | When to use                             | How figx handles it                                                               |
| --------------------------- | --------------------------------------- | --------------------------------------------------------------------------------- |
| Personal Access Token (PAT) | local CLI, server-side automation       | `figx auth login` → macOS Keychain (`service=figma-cli`) → `X-Figma-Token` header |
| OAuth 2.0                   | multi-user apps, 3rd-party integrations | not used directly; OAuth apps must be registered with Figma                       |

PATs have a **90-day maximum** (2025-04-28 policy change). figx validates
every new PAT against `/v1/me` before storing.

## Scopes — full table

All scopes below are documented at
[Scopes](https://developers.figma.com/docs/rest-api/scopes/).

### Available on every plan

| Scope                               | Grants                                   |
| ----------------------------------- | ---------------------------------------- |
| `current_user:read`                 | your name, email, profile image          |
| `file_content:read`                 | read file nodes, editor type             |
| `file_metadata:read`                | file metadata (thumbnails, timestamps)   |
| `file_versions:read`                | version history                          |
| `file_comments:read` / `write`      | comments + comment reactions             |
| `file_dev_resources:read` / `write` | dev resources attached to nodes          |
| `library_assets:read`               | published components + styles data       |
| `library_content:read`              | list published components/styles         |
| `team_library_content:read`         | team-library published components/styles |
| `projects:read`                     | list projects and files                  |
| `selections:read`                   | last user selection                      |
| `webhooks:read` / `write`           | webhook management                       |

### Enterprise-only

| Scope                    | Grants                               |
| ------------------------ | ------------------------------------ |
| `file_variables:read`    | Variables collections, modes, values |
| `file_variables:write`   | create/update/delete Variables       |
| `library_analytics:read` | library usage analytics              |
| `org:activity_log_read`  | org activity log (admin)             |
| `org:discovery_read`     | text-event data (Governance+, admin) |

### Deprecated

- `files:read` — legacy catch-all. Do not use in new tokens.

## Endpoints cheat sheet

### Files

| Endpoint                  | Method | Scope                | Notes                       |
| ------------------------- | ------ | -------------------- | --------------------------- |
| `/v1/files/:key`          | GET    | `file_content:read`  | full node tree (large)      |
| `/v1/files/:key/meta`     | GET    | `file_metadata:read` | lightweight (added 2025-04) |
| `/v1/files/:key/nodes`    | GET    | `file_content:read`  | subset by node_ids          |
| `/v1/files/:key/images`   | GET    | `file_content:read`  | export PNG/JPG/SVG/PDF      |
| `/v1/files/:key/versions` | GET    | `file_versions:read` | version history             |

### Comments

| Endpoint                      | Method     | Scope                          |
| ----------------------------- | ---------- | ------------------------------ |
| `/v1/files/:key/comments`     | GET / POST | `file_comments:read` / `write` |
| `/v1/files/:key/comments/:id` | DELETE     | `file_comments:write`          |

### Components & Styles (read-only)

| Endpoint                    | Method | Scope                  |
| --------------------------- | ------ | ---------------------- |
| `/v1/files/:key/components` | GET    | `library_assets:read`  |
| `/v1/teams/:id/components`  | GET    | `library_content:read` |
| `/v1/teams/:id/styles`      | GET    | `library_content:read` |

### Variables (Enterprise Full seat)

| Endpoint                             | Method | Scope                  |
| ------------------------------------ | ------ | ---------------------- |
| `/v1/files/:key/variables/local`     | GET    | `file_variables:read`  |
| `/v1/files/:key/variables/published` | GET    | `file_variables:read`  |
| `/v1/files/:key/variables`           | POST   | `file_variables:write` |

POST body carries the 4 arrays `variableCollections`, `variableModes`,
`variables`, `variableModeValues` — each item with `action: CREATE /
UPDATE / DELETE`.

### Dev Resources

| Endpoint                           | Method       | Scope                               |
| ---------------------------------- | ------------ | ----------------------------------- |
| `/v1/files/:key/dev_resources`     | GET / POST   | `file_dev_resources:read` / `write` |
| `/v1/files/:key/dev_resources/:id` | PUT / DELETE | `file_dev_resources:write`          |

### Webhooks V2

- `POST /v2/webhooks` — subscribe
- `GET /v2/webhooks` — list (scope: `webhooks:read`)
- `DELETE /v2/webhooks/:id`
- Retry policy: 5 min → 30 min → 3 hr on 5xx / non-200 responses.
- Signature: `X-Figma-Signature` HMAC-SHA256 with webhook secret.
- Limits: 20 per team, 5 per project, 3 per file.

### Projects & Teams

| Endpoint                 | Method | Scope           |
| ------------------------ | ------ | --------------- |
| `/v1/teams/:id/projects` | GET    | `projects:read` |
| `/v1/projects/:id/files` | GET    | `projects:read` |

### Analytics (Enterprise)

| Endpoint                                         | Method | Scope                    |
| ------------------------------------------------ | ------ | ------------------------ |
| `/v1/analytics/libraries/:key/component/actions` | GET    | `library_analytics:read` |
| `/v1/analytics/libraries/:key/component/usages`  | GET    | `library_analytics:read` |
| `/v1/analytics/libraries/:key/style/*`           | GET    | `library_analytics:read` |
| `/v1/analytics/libraries/:key/variable/*`        | GET    | `library_analytics:read` |

## Rate limits

Figma uses a **leaky-bucket algorithm** keyed by (user seat tier, endpoint
tier, plan/location). 429 responses carry a `Retry-After` header.

| Endpoint tier                                 | Dev/Full seat / minute (typical) |
| --------------------------------------------- | -------------------------------- |
| Tier 1 (cheap — metadata, list ops)           | 10–20 / min                      |
| Tier 2 (mid — file reads, comments)           | 25–100 / min                     |
| Tier 3 (heavy — image export, Variables POST) | 50–150 / min                     |

View / Collab seats have monthly caps (e.g., Tier 1 = 6 / month) and
may be throttled further during peak traffic.

**figx retry policy** already follows best practice: 401/403 stop
immediately, 429/5xx exponentially back off 5 times (2→4→8→16→32 s),
uncaught errors route through an `ERR` trap to Hermes.

## Webhook event types (V2)

| Event                    | Scope            | Typical use                            |
| ------------------------ | ---------------- | -------------------------------------- |
| `PING`                   | —                | confirmation right after subscription  |
| `FILE_UPDATE`            | `webhooks:write` | content change (throttled ~1/min/file) |
| `FILE_VERSION_UPDATE`    | "                | explicit version save                  |
| `FILE_DELETE`            | "                | —                                      |
| `FILE_COMMENT`           | "                | new comment or reply                   |
| `LIBRARY_PUBLISH`        | "                | library publish — what figx polls for  |
| `DEV_MODE_STATUS_UPDATE` | "                | layer moved to Ready for Dev (2025-05) |

`figx` doesn't create webhooks itself, but it can be driven by one: set
up a Hermes webhook listener that reacts to `LIBRARY_PUBLISH` and calls
`figx export tokens --fmt css` + git commit for auto-sync.

## Idiomatic request envelope

```bash
PAT="$(security find-generic-password -s figma-cli -a default -w)"

curl -sS -H "X-Figma-Token: $PAT" \
     "https://api.figma.com/v1/files/$FIGMA_FILE_KEY/meta" |
  jq .
```

## Government / self-hosted

- Standard base: `https://api.figma.com`
- Figma for Government: `https://api.figma-gov.com`
- Override in figx: `FIGMA_API_BASE=https://api.figma-gov.com figx files current`

## Plan matrix

| Capability                           | Starter (free) | Professional | Organization | Enterprise |
| ------------------------------------ | -------------- | ------------ | ------------ | ---------- |
| REST read                            | ✓              | ✓            | ✓            | ✓          |
| REST write (comments, dev resources) | ✓              | ✓            | ✓            | ✓          |
| Variables read (REST)                | —              | —            | —            | ✓          |
| Variables write (REST)               | —              | —            | —            | ✓          |
| Variables multi-mode in file         | —              | ✓            | ✓            | ✓          |
| Tokens Studio plugin                 | ✓              | ✓            | ✓            | ✓          |
| Webhooks V2                          | ✓              | ✓            | ✓            | ✓          |
| Library Analytics                    | —              | —            | —            | ✓          |
| Activity log API                     | —              | —            | —            | ✓          |

figx's hybrid pipeline is the way to cover Professional / Organization
accounts: Tokens Studio for Variables, REST for reads + comments +
dev_resources + webhooks.

## Sources

- [REST API index](https://developers.figma.com/docs/rest-api/)
- [Scopes](https://developers.figma.com/docs/rest-api/scopes/)
- [Rate limits](https://developers.figma.com/docs/rest-api/rate-limits/)
- [Webhooks V2](https://developers.figma.com/docs/rest-api/webhooks/)
- [Variables](https://developers.figma.com/docs/rest-api/variables/)
- [Dev Resources](https://developers.figma.com/docs/rest-api/dev-resources/)
- [Changelog](https://developers.figma.com/docs/rest-api/changelog/)
