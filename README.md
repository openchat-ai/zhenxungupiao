# 震巽股票

**纯 yoyo 手机 App** — 零外部依赖，`.ty` 源码由 `yoyo.exe` 编译为原生程序。

## 理念

yoyo 是**万能编译器**：在现有整数 opcode 基础上扩展浮点（`0x90`–`0x9F`），最终可
将同一份 `.ty` 编译到 Windows / Linux / Android / iOS，**不允许依赖任何外部库**
（无 React、无 Capacitor、无 npm、无 CRT）。

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 1 | 三进制决策 `ternary_signal.ty` | ✅ |
| Phase 2 | 定点指标库 + 浮点 opcode 规范 | 🔄 |
| Phase 3 | ELF / Mach-O 多目标后端 | ⬜ |
| Phase 4 | GUI（K 线、紫买绿卖指标子图） | ⬜ |

详见 `yoyo/docs/ROADMAP.md`、`yoyo/docs/PHASE2-FLOAT.md`。

## 目录

```
yoyo/
  compiler/yoyo.exe     官方三进制自托管编译器（非 JavaScript）
  stock_app.ty          App 主入口
  ternary_signal.ty     决策 handler 库
  lib/fp.ty             定点运算（Phase 2 过渡）
  lib/indicators.ty     SMA/趋势/RSI/MACD → trit 投票
  docs/                 浮点规范与路线图
scripts/build.sh        合并模块并编译
Makefile                零依赖构建入口
```

## 构建

```bash
make              # build/stock_app.exe + build/ternary_signal.exe
make stock        # 仅完整 App
make signal       # 仅决策核心
```

Windows 直接运行 `yoyo.exe`；Linux/macOS 需 [Wine](https://www.winehq.org/)。

## 主程序流程（stock_app.ty）

1. 载入 K 线收盘价 → `state[100..109]`
2. `H_C8` 四指标投票 → `state[10..13]`
3. `H_20` 累加 → `H_30` 决策 → `state[22]`（0 卖 / 1 持 / 2 买）

## 信号配色（Phase 4 GUI）

- **紫色** `#a855f7` — 买入
- **绿色** `#2ebd85` — 卖出

## 许可证

Apache-2.0（与 yoyo-ide 一致）
