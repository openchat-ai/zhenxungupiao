# yoyo 三进制决策核心

本目录用 [openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) 的 **yoyo 语言**
（9 个 opcode 的自托管 x86_64 PE 编译器语言）实现选股 App 的核心决策：
**「集百家之长 → 唯一买卖信号」**。

## 文件

| 文件 | 说明 |
|---|---|
| `ternary_signal.ty` | yoyo 源码：把 4 个指标的 trit 投票求和，按平衡三进制取符号得出买/持/卖 |
| `compiler/yoyo.exe` | 官方 yoyo 自托管编译器（PE32+），**非 JavaScript** |

## 编译

```bash
npm run yoyo:build
# 等价于：yoyo/compiler/yoyo.exe yoyo/ternary_signal.ty build/ternary_signal.exe
```

产物是一个 ~84 KB 的 PE32+ 可执行文件，由官方 `yoyo.exe` 编译器生成，无运行时依赖。

> Linux / macOS 需安装 Wine 才能运行 `yoyo.exe`；Windows 可直接执行。

## 为什么 GUI 不是用 yoyo 写的？

yoyo 是一门**专为编写自托管编译器**而设计的极小语言（Phase 1）：

- 只有整数状态数组，**没有浮点 / 字符串 / 文件 IO / GUI**；
- 产物是 **Windows x86_64 PE**，本机（Linux）需 wine 才能执行，且 Phase-1 程序固定 `ExitProcess(0)`，没有可观测输出。

因此 K 线绘制、手势、收藏等界面逻辑由可运行的 Web 技术（Vite + React + TypeScript）实现，
而**三进制决策这层纯整数逻辑**用 yoyo 真实编写并由 `yoyo.exe` 编译。
`ternary_signal.ty` 与 `src/ternary.ts` 中的 `analyzeCandles` 一一对应
（trit 无符号编码 0/1/2 ↔ 平衡三进制 -1/0/+1，`sum` 与中性值 4 比较）。

## 指标信号配色

K 线下方 MACD / RSI 子图及四指标信号条遵循：

- **紫色** `#a855f7` → 买入信号
- **绿色** `#2ebd85` → 卖出信号

K 线本身仍按 A 股习惯：红涨绿跌。
