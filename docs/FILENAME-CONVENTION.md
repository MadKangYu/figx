# Filename conventions — multi-brand, multi-category, never tangled

> One naming scheme that scales from a single-brand side project to a
> studio running a dozen clients, each with multiple categories and
> multiple campaigns. The goal: you can always find any file from the
> name alone, and tools like `figx` can parse it without guessing.

## The problem every large design team hits

- Two SKUs with nearly-identical file lists — which one is current?
- Five campaigns, each with "hero_v3_final_FINAL.psd"
- Four brands x three locales x six screen slots = 72 near-identical
  files that sort poorly in any file browser
- Assets cross-referenced from Figma, Drive, Notion, and Slack — no
  single naming contract

## The convention — 7 segments, hyphen-separated

```
{brand}-{category}-{subject}-{variant}-{locale}-{version}.{ext}
```

| Segment    | Examples                                  | Notes                                      |
| ---------- | ----------------------------------------- | ------------------------------------------ |
| `brand`    | `amplen`, `acme`, `client01`              | short, stable, lowercase                   |
| `category` | `skincare`, `vape`, `home`                | pick from a fixed list per brand           |
| `subject`  | `hero`, `ingredient`, `model`, `packshot` | content type on the frame                  |
| `variant`  | `pep`, `cer`, `red`, `l`, `m`             | SKU / color / size axis                    |
| `locale`   | `ko`, `en`, `ru`, `uz`, `multi`           | `multi` if language-agnostic               |
| `version`  | `v01`, `v02`, `final`                     | monotonic; `final` reserved for signed-off |
| `ext`      | `jpg`, `png`, `webp`, `gif`, `mp4`        | lowercase                                  |

Examples:

```
amplen-skincare-hero-pep-ko-v03.jpg
amplen-skincare-ingredient-cer-multi-v01.png
acme-home-packshot-red-en-final.jpg
client01-vape-model-l-uz-v02.jpg
```

## Why 7 segments?

Fewer → collisions across brands/campaigns.
More → nobody types them; people stop following the scheme.

Seven is the smallest set that keeps every discriminating axis
(brand, category, subject, variant, locale, version) visible in the
filename alone.

## Use of the version slot

- `v01`, `v02`, … during iteration.
- `final` when merged/published. Only one file per `{brand-category-
subject-variant-locale}` may carry `final`.
- `rc` (release candidate) for pre-publication review copies.
- Do not use `FINAL`, `final2`, `FINAL-FINAL`. That's the classic
  anti-pattern; `final` alone is the contract, git is the history.

## Folder layout that complements the names

```
assets/
  {brand}/
    {category}/
      originals/     # untouched, typed with the full 7-segment name
      figma-ready/   # output of `figx images prep`
      sorted/        # output of `figx assets classify`
      published/     # final assets locked for handoff
```

Keeping the same 7-segment convention at the filename level means
files can move between these folders without losing information.

## Collision-proofing

- **Unique version per path.** If two files would have the same name,
  bump version or add a disambiguator to `variant` (e.g.
  `variant=pep-large` vs `pep-small`).
- **No spaces, ever.** Hyphens only. Tools break on spaces.
- **ASCII-only.** Non-ASCII sorts inconsistently across macOS/Linux.
- **Lowercase.** Case-insensitive filesystems silently collide.

## Validator (quick check)

Drop this in your repo and run it before each handoff:

```bash
find assets -type f | grep -vE \
  '^assets/[a-z0-9]+/[a-z0-9]+/(originals|figma-ready|sorted|published)/'\
'[a-z0-9]+-[a-z0-9]+-[a-z0-9]+-[a-z0-9]+-[a-z]{2}|multi-(v[0-9]{2}|final|rc)\.[a-z0-9]+$'
```

Anything that prints is misnamed.

## Integrating with figx

`figx images prep` and `figx assets classify` both preserve filenames
(they only change extension / dimensions, never the stem), so if your
inputs follow the 7-segment convention, every downstream output does
too.

When you drive the `figma-mcp-go` `import_image` tool from an agent,
use the filename stem as the default layer name in Figma:

```
mcp__figma-mcp-go__import_image(
  path="assets/amplen/skincare/published/amplen-skincare-hero-pep-ko-v03.jpg",
  name="hero/pep/ko"   # derived from the last 3 slashes of the stem
)
```

The Figma layer tree then mirrors the asset hierarchy — one less
mental context switch.

## Multi-brand configuration

Hold the accepted values for each axis in a per-project config so the
CLI can validate:

```toml
# assets/.figx-names.toml
brands = ["amplen", "acme", "client01"]
categories = { amplen = ["skincare", "vape"], acme = ["home"], client01 = ["vape"] }
subjects = ["hero", "ingredient", "model", "packshot", "before-after", "feature"]
variants = ["pep", "cer", "red", "blue", "l", "m", "s"]
locales  = ["ko", "en", "ru", "uz", "multi"]
versions = { pattern = "^v\\d{2}$|^final$|^rc$" }
```

`figx assets classify` reads this if present and flags files whose
stems don't fit. (Planned `--validate` flag, v0.2.)

## Versioning discipline on team work

- A PR that promotes a file to `final` must be reviewed by at least
  one other designer.
- Once published, a `final` file is immutable — if you need a change,
  mint `v04` and promote that.
- Keep a `CHANGES.md` at `assets/{brand}/{category}/` so a quick
  `git log` plus the changelog tells the story without file spelunking.

## Edge cases

| Case                       | Convention                                                                     |
| -------------------------- | ------------------------------------------------------------------------------ |
| Animations (gifs, mp4s)    | Same 7 segments; `ext=gif` or `mp4`.                                           |
| Sprite sheets              | `subject=sprite`; store the frame count in the filename comment, not the stem. |
| Photoshoot raws            | Keep originals OUT of the above tree — they're not handoff artifacts.          |
| Legal-required disclaimers | `subject=disclaimer`, `variant=market-code` (e.g., `us`, `eu`).                |
| Retina @2x files           | `variant=x2` segment appended; never squeeze it into `version`.                |

## The bottom line

You don't get to "world-class multi-brand studio" by being clever
once — you get there by being boring forever. Seven segments, hyphens,
lowercase, no spaces, no non-ASCII. Everyone on the team writes the
same thing. Tools parse it. Nothing tangles.
