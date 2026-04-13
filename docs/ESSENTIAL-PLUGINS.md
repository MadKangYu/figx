# Essential Figma Plugins

> Curated list of open-source and community plugins that pair well with
> `figx`. Most live on GitHub; the first column links there. If a plugin
> requires a manifest import (dev plugin), the instructions are next to
> it.

## Core

| Plugin                       | Source                                                                                                | Role                                                                                                  | How to install                                                                                                                                                                         |
| ---------------------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Figma MCP Go**             | [vkhanhqui/figma-mcp-go](https://github.com/vkhanhqui/figma-mcp-go)                                   | Full Plugin API via MCP bridge. The primary target of `figx plugin open`.                             | `bootstrap.sh` installs this. Then in Figma Desktop: `Plugins → Development → Import plugin from manifest` → `~/Projects/figma-mcp-learning/plugins/figma-mcp-go/plugin/manifest.json` |
| **Tokens Studio for Figma**  | [tokens-studio/figma-plugin](https://github.com/tokens-studio/figma-plugin)                           | Import/export design tokens in many formats; the no-Enterprise path for creating Figma Variables.     | Figma Desktop → Resources → Community → search "Tokens Studio" → Save                                                                                                                  |
| **Figma Plugin Typings MCP** | [hoshikitsunoda/figma-plugin-typings-mcp](https://github.com/hoshikitsunoda/figma-plugin-typings-mcp) | Serves Plugin API TypeScript typings to AI agents. Useful when generating figma-mcp-go-style plugins. | `npm i -g @hoshikitsunoda/figma-plugin-typings-mcp`                                                                                                                                    |

## Bridges / MCP Servers

| Plugin                   | Source                                                                              | Role                                                 |
| ------------------------ | ----------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `figma-mcp-bridge`       | [gethopp/figma-mcp-bridge](https://github.com/gethopp/figma-mcp-bridge)             | Plugin+MCP combo that bypasses Figma API rate limits |
| `bridge`                 | [noemuch/bridge](https://github.com/noemuch/bridge)                                 | Terminal-to-Figma-Plugin API over WebSocket          |
| `Figma-MCP-Write-Bridge` | [firasmj/Figma-MCP-Write-Bridge](https://github.com/firasmj/Figma-MCP-Write-Bridge) | Manipulate Figma documents programmatically via MCP  |
| `figma-mcp-free`         | [slashdoodleart/figma-mcp-free](https://github.com/slashdoodleart/figma-mcp-free)   | Free MCP+Plugin streaming live design data           |

## Design Systems

| Plugin                      | Source                                                                                          | Role                                                                                     |
| --------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `figma-design-system-skill` | [AmroJSawan/figma-design-system-skill](https://github.com/AmroJSawan/figma-design-system-skill) | Claude Code skill for AI-driven design system audits/migrations via the Figma MCP plugin |
| `designsystem-figma-plugin` | [brreg/designsystem-figma-plugin](https://github.com/brreg/designsystem-figma-plugin)           | Import assets from Figma Community files into your own organization                      |
| `figma-edit-mcp`            | [asamuzak09/figma-edit-mcp](https://github.com/asamuzak09/figma-edit-mcp)                       | Edit Figma via MCP (text, shapes, frames)                                                |

## IDE integrations

| Plugin                             | Source                                                                                                    | Role                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `vscode-figma-mcp-helper`          | [birdea/vscode-figma-mcp-helper](https://github.com/birdea/vscode-figma-mcp-helper)                       | VSCode sidekick for figma MCP work                     |
| `figma-copilot`                    | [xlzuvekas/figma-copilot](https://github.com/xlzuvekas/figma-copilot)                                     | MCP+Plugin connectors for Cursor/Copilot to edit Figma |
| `flutter-cursor-plugin`            | [Wreos/flutter-cursor-plugin](https://github.com/Wreos/flutter-cursor-plugin)                             | Cursor plugin for Flutter + Dart MCP + Figma MCP       |
| `github-copilot-talk-to-figma-mcp` | [vitthalr/github-copilot-talk-to-figma-mcp](https://github.com/vitthalr/github-copilot-talk-to-figma-mcp) | Copilot integration with Figma                         |

## Choosing

- Using this CLI? → Stick to **Figma MCP Go** + **Tokens Studio**. That
  covers 90% of work on Professional plans.
- Need cross-IDE AI editing? → Add **figma-copilot** or
  **vscode-figma-mcp-helper** depending on your editor.
- Writing your own plugin? → Install **figma-plugin-typings-mcp** so
  your AI assistant has current Plugin API types.

## Install helper

```bash
figx plugin install            # stages figma-mcp-go (via bootstrap.sh)
# Tokens Studio: install from the in-Figma Community (no CLI path)
# Others: clone from GitHub and import manifest.json in Figma Desktop
```
