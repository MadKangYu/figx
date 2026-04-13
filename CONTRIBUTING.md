# Contributing

Thanks for your interest. This project is small on purpose — a single
bash entrypoint plus a few library files. Please keep the surface area
small and behaviors explicit.

## Ground rules

- POSIX-friendly bash. Avoid bashisms you don't need.
- `set -Eeuo pipefail` in every entrypoint.
- No network calls outside `lib/api.sh`.
- Every command emits a Hermes event on success and failure via
  `hermes_notify` (best-effort; failure of the push never fails the
  command).
- Never print secrets. PATs go through `lib/keychain.sh` only.
- Respect the 401/403 stop-immediately rule — do not retry auth errors.
- Retry 429/5xx/000 with exponential backoff (5 attempts, 2→4→8→16→32 s).

## Development setup

```bash
git clone https://github.com/MadKangYu/figx.git ~/scripts/figma-cli
ln -sf ~/scripts/figma-cli/figma ~/.local/bin/figx
figx doctor
```

Changes require no build step — edit `figma` or `lib/*.sh` and re-run
`figx version`.

## Testing

- Run `figx doctor` before and after changes.
- For Variables changes, use a scratch Figma file and `figx vars dump
scratch.json` to snapshot.
- `tools/extract_from_py.py` has no dependencies beyond stdlib; run
  `python3 -m py_compile tools/extract_from_py.py` before sending a PR.

## Pull requests

- Keep diffs focused. One intent per PR.
- Update `CHANGELOG.md` under an "Unreleased" section.
- Include a short "how I verified this" section in the PR body.
