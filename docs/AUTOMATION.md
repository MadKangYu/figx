# Automation & docs sync

Keep the repo, the tokens, and the diagram in lockstep with one
command.

## One command that does everything

```bash
./tools/docs-sync.sh --push
```

It:

1. Re-extracts design tokens from your Python source of truth
   (`--src` defaults to `~/Documents/AmpleN_Uzum_Uzb/pdp_pipeline/make_pdp.py`).
2. Re-uploads `assets/diagrams/figx-architecture.excalidraw` to
   `excalidraw.com` (anonymous, free) and captures the new share URL.
3. Rewrites the Excalidraw URL in `README.md` and `assets/README.md`.
4. Runs `bash -n` across every shell script and `py_compile` on the
   Python AST extractor.
5. Commits and pushes (with `--push`).

Without `--push` it does everything except the commit — useful for a
dry run.

## Configure via env vars

| Variable          | Default                                                |
| ----------------- | ------------------------------------------------------ |
| `FIGX_TOKENS_SRC` | `~/Documents/AmpleN_Uzum_Uzb/pdp_pipeline/make_pdp.py` |
| `FIGX_TOKENS_OUT` | `~/Documents/AmpleN_Uzum_Uzb/design-tokens`            |
| `SSL_CERT_FILE`   | set automatically if `certifi` is importable           |

## Beginners: three ways to run

1. **From inside the repo.**
   ```bash
   cd ~/path/to/figma-cli
   ./tools/docs-sync.sh
   ```
2. **One-liner after install.**
   ```bash
   ~/.local/share/figx/tools/docs-sync.sh --push
   ```
3. **Override source if your tokens live elsewhere.**
   ```bash
   FIGX_TOKENS_SRC=~/my-project/tokens.py ./tools/docs-sync.sh
   ```

## When to run it

- You edited a token constant in `make_pdp.py` (or its equivalent).
- You edited the architecture diagram.
- You cut a new release and want the README badge to point to the
  latest shareable Excalidraw.
- You changed any shell script and want `bash -n` to catch a typo
  before CI (see [`docs/CI.md`](CI.md)).

## Failure modes

| Symptom                                  | Fix                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------- |
| `unable to get local issuer certificate` | `pip install --user certifi` (the script will auto-use it)           |
| `upload failed`                          | check network, retry; upload is anonymous, no rate limit in practice |
| `extract_from_py.py: source not found`   | pass `--src <path>` or export `FIGX_TOKENS_SRC`                      |
| `push rejected`                          | run `gh auth refresh -s workflow` if the change touches `.github/`   |
