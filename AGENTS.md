# AGENTS.md

## Cursor Cloud specific instructions

This repo (震巽股票 / "Zhèn-Xùn Stocks") is an experimental, zero-external-dependency
A-share ternary trading-signal project. There is **no server, database, web app, or
package manager** — nothing long-running to start. "Running the application" means
either (a) running the pure-`awk` backtest engine over the committed data in
`research/archive/`, or (b) compiling `.ty` sources to native binaries via the
committed `yoyo.exe` compiler under Wine.

Standard commands live in the root `Makefile` and `README.md`; don't duplicate them.
Below are only the non-obvious caveats discovered during setup.

### What actually works today (use this to demo/test)

- The **pure-`awk` backtest engine** is the genuinely working, self-contained part.
  It reads the frozen CSVs in `research/archive/` and recomputes the 7-vote
  buy/hold/sell (trit `2/1/0`) signals plus returns/Sharpe/drawdown:
  - `make research-v2`, `make research-v3`, `make research-v4`, `make research-v5-compare`
  - These need only `make` + `awk` (both preinstalled); **no Wine, no network, no Python**.
  - Each target **overwrites committed files** under `research/archive/` (CSV/JSON/MD,
    including timestamps). If you don't intend to commit regenerated data, run
    `git checkout -- research/archive/` afterward to keep the tree clean.

### Wine / yoyo.exe compiler caveats (important)

- Wine is required to *execute* `yoyo/compiler/yoyo.exe` (a committed PE32+ x86-64
  binary) on Linux. It is **not guaranteed to be preinstalled** on a fresh VM (verify
  with `wine --version`; `~/.wine` may be absent) and it is **not part of the update
  script** (it's a system dependency). Crucially, you do **not** need Wine to run/demo
  the working part of this repo — the pure-`awk` backtest engine below is fully
  self-contained. Installing Wine only lets you reproduce the documented `Error 5`
  failure of the stub compiler (see next bullet), so it is optional. If you do need it,
  install via `apt` and let it initialize `~/.wine` on first run.
- **The committed `yoyo.exe` is a fixed-output bootstrap stub, not a working
  compiler.** Empirically it: ignores its command-line arguments, reads a hardcoded
  `input.ky` from the current directory, always writes a **constant** `output.exe`
  (identical checksum regardless of input), and exits with **code 5**. Because of the
  non-zero exit, the Wine-backed Make targets (`make signal`, `make stock`,
  `make stock-gui`, `make bootstrap`, `make stock-gui-elf`, and the
  `build_research.sh`-based targets such as `make hold-ratio`, `make research-walk`,
  `make butterfly-demo`, `make psychology-demo`) **fail with `Error 5`** and cannot
  produce real binaries. This is a limitation of the committed compiler artifact, not
  of the environment — do not treat these failures as environment breakage.
- Side effect: any Wine-backed build run leaves a stray `output.exe` in the repo root.
  Remove it (`rm -f output.exe`) so it doesn't show up as untracked.
- Note: without Wine, the same build scripts *skip* compilation and exit 0 (printing
  "install Wine to run yoyo.exe on Linux"); with Wine they actually run the stub and
  surface the `Error 5` above.

### Optional data-fetch tooling (not needed to run/test)

- `requirements-optional.txt` (`akshare`, `openbb`, `openbb-akshare`, `easy-tdx`) is
  only for regenerating market data via `make fetch-news` / `make fetch-ticks*` /
  `make extend-hist`. These require internet access to Chinese market endpoints
  (Eastmoney/AKShare) and are intentionally not installed. The archived CSVs are
  already frozen, so the backtests run without them.
