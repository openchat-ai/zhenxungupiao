# yoyo 三进制决策核心

本目录用 [openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) 的 **yoyo 语言**
（9 个 opcode 的自托管 x86_64 PE 编译器语言）实现选股 App 的核心决策：
**「集百家之长 → 唯一买卖信号」**。

## 文件

| 文件 | 说明 |
|---|---|
| `ternary_signal.ty` | yoyo 源码：把 4 个指标的 trit 投票求和，按平衡三进制取符号得出买/持/卖 |
| `compiler/` | 从 yoyo-ide 原样 vendoring 的 yoyo 编译器（`yoyo.cjs` / `encode-x64.cjs` / `pe-builder.cjs`），Apache-2.0，零依赖 |

## 编译

```bash
npm run yoyo:build
# 等价于：node yoyo/compiler/yoyo.cjs yoyo/ternary_signal.ty build/ternary_signal.exe
```

产物是一个 ~84 KB 的 PE32+ 可执行文件，由官方 yoyo 编译器生成，无运行时依赖。

## 为什么 GUI 不是用 yoyo 写的？

yoyo 是一门**专为编写自托管编译器**而设计的极小语言（Phase 1）：

- 只有整数状态数组，**没有浮点 / 字符串 / 文件 IO / GUI**；
- 产物是 **Windows x86_64 PE**，本机（Linux）需 wine 才能执行，且 Phase-1 程序固定 `ExitProcess(0)`，没有可观测输出。

因此 K 线绘制、手势、收藏等界面逻辑由可运行的 Web 技术（Vite + React）实现，
而**三进制决策这层纯整数逻辑**用 yoyo 真实编写并由官方编译器编译。
`ternary_signal.ty` 与 `src/ternary.ts` 中的 `computeSignals` 一一对应
（trit 无符号编码 0/1/2 ↔ 平衡三进制 -1/0/+1，`sum` 与中性值 4 比较）。
