# 震巽股票 · yoyo 路线图

## 阶段状态

| Phase | 内容 | 状态 |
|-------|------|------|
| 1 | 三进制决策 `ternary_signal.ty` | ✅ |
| 2 | 浮点 opcode `0x90–0x9F` + `float_runtime.ty` | ✅ 补丁已合并 |
| 3 | ELF64 `A2 01` 多目标 | ✅ 补丁 + `stock_gui_elf.ty` |
| 4 | GUI 帧缓冲 + 紫买绿卖 `chart.ty` | ✅ 首版 |
| 5 | 时事扰动 η + 蝴蝶效应 `perturbation.ty` | ✅ v2 |
| 6 | 无问占比 + 文献参数 `wuwen.ty` `params.ty` | ✅ v2.1 |
| 7 | 心理学第 6 票 `psychology.ty` | ✅ v3 |
| 8 | 逐笔主动买卖第 7 票 `aggressive.ty` + 东财抓取 | ✅ |
| 9 | OpenBB 新闻 η + easy_tdx 历史逐笔 + v4 七票回测 | ✅ |
| 10 | **纯 yoyo 回测**（LoadFile + csv.ty，替代 awk） | 🚧 骨架已建 |

### Phase 10 迁移边界

| 层 | 现状 | 目标 |
|----|------|------|
| 七票决策 | ✅ `lib/*.ty` | 已纯 yoyo |
| v2–v5 全量回测 | `scripts/backtest_v*.awk` | `research/backtest_v*.ty` + `make research-v2-yoyo` |
| 数据抓取 | `fetch_*.sh`（curl） | 保留为可选 export，不进运行时 |
| 编译拼接 | `build_research.sh` | 可收敛为 Makefile `cat` + `yoyo.exe` |

**卡点**：`LoadFile` 现仅认 `input.ky`（str_idx=0）；CSV 浮点解析需 `mem.ty`+`csv.ty` 补全；组合 Sharpe/JSON 需 `float_runtime.ty` 或定点近似。

## 构建

```bash
make merge            # 合并编译器补丁 → build/yoyo_merged.ty
make bootstrap        # yoyo.exe → build/yoyo_next.exe（需 Wine）
make stock-gui        # PE 版 GUI App
make stock-gui-elf    # ELF 版（需 bootstrap 后）
make signal           # 仅决策核心
make research-walk    # 纯 yoyo 五票投票演示
make research-verify  # 实证锚点校验
make fetch-ticks        # 东财当日逐笔 → archive/tick_*.csv
make fetch-ticks-tdx      # 通达信逐笔，仅 2026 年 → archive/tick_hist/
make fetch-news         # AKShare/OpenBB 同源新闻 → news_daily_eta.csv
make extend-hist        # 延伸日线至今日（可选 Python）
make research-v4        # 七票 + 新闻 η + 历史逐笔回测
make research-v2-yoyo   # 纯 yoyo v2 单股回测（读 input.ky，Phase 10）
make tick-demo          # 第 7 票主动买卖演示
make news-demo          # 新闻 η 增强演示
make research-verify-v3 # v3 锚点
make hold-ratio         # 无问占比：平淡 vs 急涨 + 文献锚
make butterfly-demo   # 蝴蝶效应：1 元扰动翻转决策
```

## 文档

- `docs/PHASE2-FLOAT.md` — 浮点 opcode
- `docs/PHASE3-ELF.md` — ELF64 后端
- `docs/PHASE4-GUI.md` — GUI opcode + 配色
- `docs/PRIOR-RESEARCH.md` — 前人成果与可调参数
- `docs/PSYCHOLOGY.md` — **行为金融心理学第 6 票**
- `docs/THEORY-TERNARY-METAPHYSICS.md` — 三进制与股票预测（含 archive 实证）
- `docs/TICK-DATA-SOURCES.md` — 逐笔来源（东财 push2）
- `docs/OPENBB.md` — **OpenBB 开源平台调研**（A 股扩展、与 yoyo 边界）
- `research/archive/` — 固化回测数据（零 Python 运行时）

## 零依赖

仅 `yoyo/compiler/yoyo.exe`，无 npm / React / Capacitor。
