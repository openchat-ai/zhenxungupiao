# yoyo 三进制决策核心

见 `docs/ROADMAP.md`。本目录全部用 **yoyo 语言**（`.ty`）编写，由 `compiler/yoyo.exe` 编译。

## 编译（直接 yoyo.exe，不用 make）

```bash
# 推荐：合并 + 编译一条脚本
./scripts/compile.sh signal          # → build/ternary_signal.exe
./scripts/compile.sh stock           # → build/stock_app.exe
./scripts/compile.sh flow_signal     # → build/flow_signal_demo.exe

# 或手敲（Windows）
yoyo/compiler/yoyo.exe build/flow_signal_demo.ty build/flow_signal_demo.exe
```

合并规则与 lib 顺序见 [`docs/COMPILE.md`](docs/COMPILE.md)。

<details><summary>仍可用 make（薄封装，非必须）</summary>

```bash
make signal
make stock
make flow-signal-demo
```

</details>

## 文件

| 文件 | 说明 |
|------|------|
| `stock_app.ty` | App 主入口 |
| `ternary_signal.ty` | 四指标 trit 投票 → 唯一买卖信号 |
| `lib/fp.ty` | 定点运算（Phase 2 过渡，待换真浮点 opcode） |
| `lib/indicators.ty` | 技术指标投票 |
| `compiler/yoyo.exe` | 官方自托管编译器 |
| `docs/PHASE2-FLOAT.md` | 浮点 opcode `0x90`–`0x9F` 规范 |
| `docs/THEORY-TERNARY-METAPHYSICS.md` | 三进制 × 股票预测 × 震巽玄学理论 |

## 零依赖

- 不用 JavaScript 编译器（已移除 `yoyo.cjs`）
- 不用 npm / React / Capacitor
- 产物为 PE 原生程序，无运行时库
