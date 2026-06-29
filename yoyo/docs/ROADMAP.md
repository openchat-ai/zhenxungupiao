# 震巽股票 · yoyo 路线图

## 阶段状态

| Phase | 内容 | 状态 |
|-------|------|------|
| 1 | 三进制决策 `ternary_signal.ty` | ✅ |
| 2 | 浮点 opcode `0x90–0x9F` + `float_runtime.ty` | ✅ 补丁已合并 |
| 3 | ELF64 `A2 01` 多目标 | ✅ 补丁 + `stock_gui_elf.ty` |
| 4 | GUI 帧缓冲 + 紫买绿卖 `chart.ty` | ✅ 首版 |

## 构建

```bash
make merge            # 合并编译器补丁 → build/yoyo_merged.ty
make bootstrap        # yoyo.exe → build/yoyo_next.exe（需 Wine）
make stock-gui        # PE 版 GUI App
make stock-gui-elf    # ELF 版（需 bootstrap 后）
make signal           # 仅决策核心
```

## 文档

- `docs/PHASE2-FLOAT.md` — 浮点 opcode
- `docs/PHASE3-ELF.md` — ELF64 后端
- `docs/PHASE4-GUI.md` — GUI opcode + 配色
- `docs/THEORY-TERNARY-METAPHYSICS.md` — **三进制与股票预测的玄学关系**（理论扩充）

## 零依赖

仅 `yoyo/compiler/yoyo.exe`，无 npm / React / Capacitor。
