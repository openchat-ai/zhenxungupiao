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

## 构建

```bash
make merge            # 合并编译器补丁 → build/yoyo_merged.ty
make bootstrap        # yoyo.exe → build/yoyo_next.exe（需 Wine）
make stock-gui        # PE 版 GUI App
make stock-gui-elf    # ELF 版（需 bootstrap 后）
make signal           # 仅决策核心
make research-walk    # 纯 yoyo 五票投票演示
make research-verify  # 实证锚点校验
make research-v2        # 八股全量 v2 回测 → archive/backtest_v2_*
make research-verify-v2 # v2 锚点
make hold-ratio         # 无问占比：平淡 vs 急涨 + 文献锚
make butterfly-demo   # 蝴蝶效应：1 元扰动翻转决策
```

## 文档

- `docs/PHASE2-FLOAT.md` — 浮点 opcode
- `docs/PHASE3-ELF.md` — ELF64 后端
- `docs/PHASE4-GUI.md` — GUI opcode + 配色
- `docs/PRIOR-RESEARCH.md` — 前人成果与可调参数
- `docs/QUANT-STRATEGIES.md` — **经典量化策略与盈利逻辑**
- `docs/THEORY-TERNARY-METAPHYSICS.md` — 三进制与股票预测（含 archive 实证）
- `research/archive/` — 固化回测数据（零 Python 运行时）

## 零依赖

仅 `yoyo/compiler/yoyo.exe`，无 npm / React / Capacitor。
