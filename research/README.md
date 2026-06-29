# 实证数据存档（零 Python）

本目录数据为 **2018–2024 A 股八股回测（archive v1，四票技术面）** 的一次性导出结果，已固化入库。  
**未含时事扰动 η 层**；v2 五票逻辑见 `yoyo/lib/perturbation.ty` 与 `make butterfly-demo`。  
**工具链不要求 Python**；读取结论只需打开 JSON/CSV，或用 yoyo 编译演示程序。

## 文件

| 文件 | 说明 |
|------|------|
| `archive/backtest_summary.json` | 汇总：Sharpe、corr、持有态占比等 |
| `archive/backtest_by_stock.csv` | 分标的绩效 |
| `archive/BACKTEST_REPORT.md` | 人类可读报告 |

数据来源：[AkShare](https://github.com/akfamily/akshare) `stock_zh_a_hist`（qfq），导出后不再依赖该库。

## 纯 yoyo 复现（投票逻辑）

```bash
make research-walk      # → build/walk_forward.exe（五票）
make butterfly-demo     # → 蝴蝶效应：1 元扰动翻转决策
```

`yoyo/research/walk_forward.ty` 在嵌入的 20 日行情上执行与 `ternary_signal.ty` 相同的**五票**投票（含 `perturbation.ty`），  
统计买/持/卖次数，**仅用 yoyo.exe 编译**。

## 为何不用 Python？

震巽股票坚持 **yoyo 三进制一条道**：

- Python = 二进制生态里的脚本层，与 React/Capacitor 同属「外部库时代」
- 实证结论已存档；逻辑验证在 `.ty` 里完成
- 全量重跑需将 CSV 行情编入 `.ty` 或扩展 yoyo 的 `50` LoadFile + 浮点 opcode（Phase 2）
