# Uploading images to Figma cleanly

> Fixes the three things that silently kill a Finder → Figma drag:
> HEIC format, oversize pixels, and too-large bytes.

## The problem

1. **HEIC from iPhone** — Figma Desktop can't decode HEIC/HEIF. The
   drag succeeds but the frame shows a broken icon.
2. **Images over 4096 × 4096 px** — Figma's image cap. The drag
   succeeds locally but the render is empty; nothing in Figma warns
   you.
3. **Gigantic byte size** — a 20 MB JPEG times out during the drag
   when you select 50 of them at once.

Finder gives you no warning for any of these.

## The fix (one command)

```bash
figx images prep ~/Pictures/shoot-2026-04  --out ~/Pictures/figma-ready
```

Produces a parallel directory of drag-ready files:

- HEIC / HEIF → JPEG
- WebP / GIF → JPEG
- PNG preserved (alpha kept)
- Anything > 4096 px on either axis is downscaled with `sips -Z 4096`
- JPEG re-encoded at `q=92` (configurable) — about 1/3 the byte size
  with no visible loss

Originals are never touched.

Then just drag the `figma-ready/` folder contents into Figma.

## Flags

```
figx images prep <dir-or-file>
  --out <dir>       default: ./figma-ready
  --max <px>        default: 4096 (Figma's cap)
  --quality <1-100> default: 92    (JPEG quality)
```

## Why we don't upload through the API

Figma's REST `/v1/files/:key/images` endpoint is **read-only** — it
returns rendered exports, it can't accept uploads. The only supported
upload path is either (a) drag-and-drop in Figma Desktop, or (b) the
plugin API's `createImageAsync`. figx's `images prep` removes the
friction from (a); the plugin path is available via figma-mcp-go's
`import_image` tool if you need fully scripted uploads.

## Bulk automated uploads (agent path)

From any figma-mcp-go-connected agent:

```
mcp__figma-mcp-go__import_image(
  path="/Users/yu/Pictures/figma-ready/IMG_0042.jpg",
  x=0, y=0, width=1080, height=1440
)
```

The plugin reads the local file directly, so no HTTP server needed.
`figx images prep` first to keep each image under Figma's 4096-px
limit.

## Common cases

- **49 iPhone shots for a PDP.** `sips` handles HEIC in ~1.5 s per
  image on M-series; whole batch < 2 min.
- **Design handoff from web screenshots.** PNG input, so this is a
  no-op for format — but `--max 1920` usually cuts file size enough
  to make multi-select drag reliable.
- **Product photography at 8000 px.** Downscale to 4096 px first with
  `--max 4096`; the image still looks the same at any practical
  Figma zoom level.

## If it still fails

- Check `figx permissions` — Finder needs disk access if you prepared
  outside `~/Documents`.
- Verify the destination Figma file isn't locked for edit.
- Drag at most 20 files at once; Figma's drop handler gets flaky
  beyond that.
