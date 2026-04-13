# Essential Figma Community plugins

> Install these inside Figma Desktop (`Resources → Community → search`).
> All free. Listed by priority for the figx hybrid workflow.

## 🔴 Required

| Plugin                        | Publisher     | Why                                                                                                                             |
| ----------------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Tokens Studio for Figma**   | Tokens Studio | Imports `tokens.studio.json` from figx; creates Variables with Pep/Cer modes on any paid plan. The core of the hybrid pipeline. |
| **Figma MCP Go** (dev plugin) | vkhanhqui     | Full Plugin API over MCP for Styles, Components, Frames. `figx plugin install` auto-imports the manifest.                       |

## 🟡 Strongly recommended

| Plugin                                 | What it adds                                                                                                                                                          |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Variables to CSS**                   | One-click export of the current Variables collection to a CSS custom-properties snippet — useful for independent verification against `figx export tokens --fmt css`. |
| **Style Dictionary** (by Lucia Canedo) | Multi-platform token distribution (iOS, Android, web) from a single source. Good when the team needs tokens beyond web.                                               |
| **Instance Finder**                    | Bulk manage component instances — essential after you publish new library Variables and want to propagate updates.                                                    |
| **Auto Layout Helper**                 | Snap elements to an 8pt grid automatically — matches the `Spacing` collection figx generates.                                                                         |
| **Contrast**                           | Runs WCAG AA/AAA contrast checks. Necessary whenever SKU-mode colors change.                                                                                          |

## 🟢 Nice to have

| Plugin                 | When to reach for it                                                                    |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Color Designer**     | Generating tonal ramps for new SKUs (e.g., extending Pep/Cer to a third brand).         |
| **Content Reel**       | Populating placeholder text in templates (Korean / Russian / Uzbek sample text).        |
| **Figma to React**     | One-off design-to-code, though the official Figma MCP + v0 usually beats it on quality. |
| **Component Replacer** | Swapping large groups of instances after a Variables refactor.                          |

## Install order

1. Open Figma Desktop and sign in.
2. Save **Tokens Studio for Figma** (Community).
3. Run `figx plugin install` in terminal → figx auto-imports Figma MCP Go.
4. Open any file. `Plugins → Development → Figma MCP Go` should now be listed.
5. Save the 🟡 strongly-recommended plugins as you need them.

## Verify

```bash
figx plugin status          # WS + manifest sanity
figx plugin open            # launches Figma MCP Go via menu click
figx permissions            # macOS perms required for the above
```

If `figx plugin open` works and `mcp__figma-mcp-go__get_metadata` returns
file info, the plugin toolchain is healthy.

## Troubleshooting

- A Community plugin doesn't show up after Save → restart Figma Desktop.
- `figx plugin install` fails with "Development submenu not found" →
  set Figma Desktop language to English/Korean (supported locales) or
  import the manifest manually once via the menu.
- Variables won't push → your account isn't on Professional+; upgrade
  in Settings → Plans, then retry from Tokens Studio.
