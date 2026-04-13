# Assets

## Diagrams

- `diagrams/figx-architecture.excalidraw` — hybrid pipeline diagram.
  Open at [excalidraw.com](https://excalidraw.com) by drag-and-drop,
  or view the live shareable link:
  [https://excalidraw.com/#json=\_ZstONCsu_jsD2-83qhQ3,8REr9ToG-GU9R52HdA8dYA](https://excalidraw.com/#json=_ZstONCsu_jsD2-83qhQ3,8REr9ToG-GU9R52HdA8dYA)

## Screenshots

`screenshots/` holds terminal captures used in the README.

### Capture conventions

- macOS screenshot: `cmd+shift+4` then drag a selection of the terminal
- Naming: `NN-<command>.png` (e.g. `01-doctor.png`, `02-plugin-open.png`)
- Max width 1200 px, PNG, no dark mode switching
- Include only the relevant command + output (crop chrome)

To regenerate captures from scratch: `figx doctor; figx auth status;
figx files current; figx plugin status; figx plugin open; figx hermes check`
