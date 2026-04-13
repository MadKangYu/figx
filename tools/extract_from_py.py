#!/usr/bin/env python3
"""Extract design tokens from pdp_pipeline/make_pdp.py and emit 3 formats.

Outputs (written to the directory passed via --out):
- tokens.dtcg.json          — W3C Design Tokens Community Group spec
- tokens.css                — CSS custom properties (for web code)
- tokens.studio.json        — Tokens Studio for Figma plugin import format
                               (https://tokens.studio — works on all plans,
                                imports Variables via Figma Plugin API)

Usage:
    python3 extract_from_py.py \\
        --src  /Users/yu/Documents/AmpleN_Uzum_Uzb/pdp_pipeline/make_pdp.py \\
        --out  /Users/yu/Documents/AmpleN_Uzum_Uzb/design-tokens

This replaces the Figma Variables REST API path for non-Enterprise accounts.
"""
from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path


def _literal(node: ast.AST):
    """Safe-eval a module-level literal."""
    return ast.literal_eval(node)


def extract_tokens(src: Path) -> dict:
    """Parse top-level assignments PAD, SIZE, LH, PALETTE, HL, COLORS from make_pdp.py."""
    tree = ast.parse(src.read_text(encoding="utf-8"))
    want = {"PAD", "SIZE", "LH", "PALETTE", "HL", "COLORS"}
    found: dict[str, object] = {}
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id in want:
                found[target.id] = _literal(node.value)
    missing = want - found.keys()
    if missing:
        raise SystemExit(f"missing tokens in {src}: {missing}")
    return found


def build_dtcg(t: dict) -> dict:
    """W3C Design Tokens Community Group format (2026 draft)."""
    def color(h: str) -> dict:
        return {"$type": "color", "$value": h}

    def dim(n: float) -> dict:
        return {"$type": "dimension", "$value": f"{n}px"}

    def num(n: float) -> dict:
        return {"$type": "number", "$value": n}

    pep = {k: color(v) for k, v in t["COLORS"]["pep"].items()}
    cer = {k: color(v) for k, v in t["COLORS"]["cer"].items()}

    return {
        "$schema": "https://design-tokens.github.io/community-group/format/",
        "color": {
            "base": {k: color(v) for k, v in t["PALETTE"].items()},
            "sku": {"pep": pep, "cer": cer},
        },
        "spacing": {k: dim(v) for k, v in t["PAD"].items()},
        "fontSize": {k: dim(v) for k, v in t["SIZE"].items()},
        "lineHeight": {k: num(v) for k, v in t["LH"].items()},
        "hairline": {k: dim(v) for k, v in t["HL"].items()},
    }


def build_css(t: dict) -> str:
    """CSS custom properties. SKU defaults to Pep; toggle via [data-sku='cer']."""
    out = [":root {"]
    for k, v in t["PALETTE"].items():
        out.append(f"  --color-base-{k}: {v};")
    for k, v in t["COLORS"]["pep"].items():
        out.append(f"  --color-sku-{k}: {v};")
    for k, v in t["PAD"].items():
        out.append(f"  --spacing-{k}: {v}px;")
    for k, v in t["SIZE"].items():
        out.append(f"  --font-size-{k}: {v}px;")
    for k, v in t["LH"].items():
        out.append(f"  --line-height-{k}: {v};")
    for k, v in t["HL"].items():
        out.append(f"  --hairline-{k}: {v}px;")
    out.append("}")
    out.append("")
    out.append("[data-sku='cer'] {")
    for k, v in t["COLORS"]["cer"].items():
        out.append(f"  --color-sku-{k}: {v};")
    out.append("}")
    return "\n".join(out) + "\n"


def build_tokens_studio(t: dict) -> dict:
    """Tokens Studio for Figma plugin format.

    Sets = discrete layers. User imports in Tokens Studio, enables 'base' + one of
    'sku/pep' or 'sku/cer', and pushes to Figma Variables via the plugin (no REST).
    """
    def color_set(pairs: dict) -> dict:
        return {k: {"value": v, "type": "color"} for k, v in pairs.items()}

    def num_set(pairs: dict, tok_type: str) -> dict:
        return {k: {"value": v, "type": tok_type} for k, v in pairs.items()}

    return {
        "base": {
            "color": color_set(t["PALETTE"]),
            "spacing": num_set(t["PAD"], "spacing"),
            "fontSize": num_set(t["SIZE"], "fontSizes"),
            "lineHeight": num_set(t["LH"], "lineHeights"),
            "hairline": num_set(t["HL"], "sizing"),
        },
        "sku/pep": {"color": {"sku": color_set(t["COLORS"]["pep"])}},
        "sku/cer": {"color": {"sku": color_set(t["COLORS"]["cer"])}},
        "$themes": [
            {"id": "pep", "name": "Peptide", "selectedTokenSets": {"base": "enabled", "sku/pep": "enabled"}},
            {"id": "cer", "name": "Ceramide", "selectedTokenSets": {"base": "enabled", "sku/cer": "enabled"}},
        ],
        "$metadata": {"tokenSetOrder": ["base", "sku/pep", "sku/cer"]},
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=Path, required=True, help="make_pdp.py path")
    ap.add_argument("--out", type=Path, required=True, help="output directory")
    args = ap.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    t = extract_tokens(args.src)

    (args.out / "tokens.dtcg.json").write_text(
        json.dumps(build_dtcg(t), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    (args.out / "tokens.css").write_text(build_css(t), encoding="utf-8")
    (args.out / "tokens.studio.json").write_text(
        json.dumps(build_tokens_studio(t), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"✓ wrote tokens.dtcg.json / tokens.css / tokens.studio.json to {args.out}")
    print(f"  collections: {len(t)}; palette={len(t['PALETTE'])}, "
          f"sku_pep={len(t['COLORS']['pep'])}, sku_cer={len(t['COLORS']['cer'])}, "
          f"spacing={len(t['PAD'])}, size={len(t['SIZE'])}, lh={len(t['LH'])}, "
          f"hairline={len(t['HL'])}")


if __name__ == "__main__":
    main()
