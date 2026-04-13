# Asset pipeline — from Drive/iCloud to Figma, classified

> End-to-end recipe for the "I have 200 photos from the shoot, where
> does each one go?" problem. Covers Google Drive ingestion, HEIC
> handling, auto-classification into model / gif / PDP buckets, and
> final drop into Figma.

## The workflow that previously broke

1. Designer shoots 100+ iPhone photos, exports to Google Drive.
2. You mount Drive on the Mac, drag into Finder, try to drop into
   Figma — HEIC rejected, aspect ratios wrong, nothing labeled.
3. Manual sort takes 40 minutes per shoot.

## The figx workflow

```
Drive  →  rclone mount  →  figx images prep  →  figx assets classify  →  Figma drop
                            (format + size)       (model / gif / pdp)
```

Three commands, no UI.

## 1. Ingest from Google Drive

### rclone (recommended)

```bash
brew install rclone
rclone config          # one-time — choose "drive"
rclone mount amplen-drive:AMPLEN ~/Drives/amplen --daemon
```

Files now appear under `~/Drives/amplen` like any local folder.
figx reads directly — no upload step.

### alternatives

- **Google Workspace MCP** (`mcp__google-workspace__*`) — listed in
  the current Codex config. Agent can `list_drive_items`,
  `get_drive_file_content`. Best when the files are small metadata;
  rclone is faster for big image batches.
- **`gdrive-downloader`** — shell helper for one-shot batch download.
- **iCloud Drive** — mounted at `~/Library/Mobile Documents/`. Same
  flow below applies.

## 2. Format-normalize

```bash
figx images prep ~/Drives/amplen/shoot-2026-04 --out ~/tmp/ready
```

HEIC → JPG, >4096 px → downscaled, re-encoded at q=92. Originals
stay in Drive untouched.

## 3. Auto-classify

```bash
python3 ~/scripts/figma-cli/tools/asset-classify.py ~/tmp/ready --out ~/tmp/sorted
```

Output tree:

```
~/tmp/sorted/
  model/       ← portrait, ≥1200px tall (model cuts / face shots)
  gif/         ← sequence filenames (IMG_0001…0024) — burst source
  pdp/         ← square/landscape ≥800px (detail-page hero, packshots)
  ambiguous/   ← review manually
```

Symlinks by default; pass `--move` to relocate.

## Classification rules

| Bucket      | Rule                                                            |
| ----------- | --------------------------------------------------------------- |
| `model`     | aspect ratio `h/w >= 1.2` AND height `>= 1200 px`               |
| `gif`       | filename part of a sequence of ≥3 numbered files (`IMG_0001..`) |
| `pdp`       | aspect ratio between 0.7 and 1.4 AND max side `>= 800 px`       |
| `ambiguous` | anything else                                                   |

Heuristics are intentionally conservative — precision > recall. Do a
spot-check on `ambiguous/` before dropping into Figma.

## 4. Drop into Figma

Two paths:

### Manual (fastest for one-off)

- Open Figma file.
- Select all in each bucket directory in Finder.
- Drag into the target frame.

### Agent-driven (scripted for repeatable)

```
mcp__figma-mcp-go__import_image(path="/Users/.../sorted/pdp/hero.jpg",
                                x=0, y=0, width=1080, height=1440)
```

figma-mcp-go's `import_image` reads the local path directly — no
HTTP server needed. Bulk with a short python script driving the MCP.

## Improving the classifier (optional)

The stdlib-only classifier uses shape heuristics. To get semantic
labels (face vs product vs lifestyle) add a local vision model:

```bash
brew install ollama
ollama pull moondream:latest    # 1.8B, CPU-friendly
```

Then pipe each image through `ollama run moondream:latest
"classify this: model / product / lifestyle. answer one word."` and
merge with the heuristic output. `figx assets classify --vision` is
a planned flag (v0.2).

## Full one-liner for an entire shoot

```bash
figx images prep ~/Drives/amplen/shoot-2026-04 --out /tmp/ready && \
python3 ~/scripts/figma-cli/tools/asset-classify.py /tmp/ready --out /tmp/sorted && \
open /tmp/sorted
```

Finder opens each bucket; drag each into the matching Figma frame.

## Why not automate the final drop?

- `import_image` (figma-mcp-go) works but requires you to decide the
  x/y/size — that is a design decision, not an automation one.
- For static detail-page slots where the frame is fixed, Pro teams
  script the drop. For one-offs, the Finder drag is faster.

## Google Drive gotchas

- **Trashed files appear in `rclone ls`** — pass `--drive-trashed-only=false`.
- **Offline files show 0 bytes** — run `rclone vfs-refresh` after
  mount.
- **Duplicates with same filename** — Drive allows this but your
  mount won't. Use `rclone dedupe` first.
- **Shared drive vs My Drive** — different remote configs. Use
  `rclone config` to add both.

## Related docs

- [`IMAGE-UPLOAD.md`](IMAGE-UPLOAD.md) — the format/size half of the
  pipeline.
- [`INTEGRATIONS.md`](INTEGRATIONS.md) — Google Workspace MCP (when
  you want agents to handle Drive directly).
