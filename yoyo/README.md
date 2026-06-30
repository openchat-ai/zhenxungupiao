# yoyo 三进制决策核心

见 `docs/ROADMAP.md`。本目录全部用 **yoyo 语言**（`.ty`）编写，由 `compiler/yoyo.exe` 编译。

## 编译

```bash
make signal    # → build/ternary_signal.exe
make stock     # → build/stock_app.exe（合并 lib/ + 主程序）
```

## 文件

| 文件 | 说明 |
|------|------|
| `stock_app.ty` | App 主入口 |
| `ternary_signal.ty` | 四指标 trit 投票 → 唯一买卖信号 |
| `lib/fp.ty` | 定点运算（Phase 2 过渡，待换真浮点 opcode） |
| `lib/indicators.ty` | 技术指标投票 |
| `compiler/yoyo.exe` | 官方自托管编译器 |
| `docs/PHASE2-FLOAT.md` | 浮点 opcode `0x90`–`0x9F` 规范 |

## 零依赖

- 不用 JavaScript 编译器（已移除 `yoyo.cjs`）
- 不用 npm / React / Capacitor
- 产物为 PE 原生程序，无运行时库
