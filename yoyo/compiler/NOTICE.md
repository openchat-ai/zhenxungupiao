# Vendored YOYO compiler

These files are vendored **unmodified in behavior** from
[openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) (`src/`), licensed
under Apache-2.0 (same license as this repository):

| Vendored file | Origin |
|---|---|
| `yoyo.cjs` | `src/yoyo.js` |
| `encode-x64.cjs` | `src/encode-x64.js` |
| `pe-builder.cjs` | `src/pe-builder.js` |

The only edits are the `.js` → `.cjs` rename (this app's `package.json` sets
`"type": "module"`, so the CommonJS compiler is kept as `.cjs`) and the matching
`require()` paths inside `yoyo.cjs`. No compiler logic was changed.
