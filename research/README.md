# 实证数据存档（零 Python）

本目录数据为 **2018–2024 A 股八股回测（archive v1，四票技术面）** 的一次性导出结果，已固化入库。  
**未含时事扰动 η 层**；v2 五票逻辑见 `yoyo/lib/perturbation.ty` 与 `make butterfly-demo`。  
**工具链不要求 Python**；读取结论只需打开 JSON/CSV，或用 yoyo 编译演示程序。

## 文件

| 文件 | 说明 |
|------|------|
| `archive/backtest_v2_summary.json` | **v2 五票全量回测汇总**（`make research-v2`） |
| `archive/backtest_v2_by_stock.csv` | v2 分标的 + 动量/均值回归对照 |
| `archive/BACKTEST_V2_REPORT.md` | v2 人类可读报告 |
| `archive/backtest_by_stock.csv` | 分标的绩效 |
| `archive/BACKTEST_REPORT.md` | 人类可读报告 |

数据来源：[AkShare](https://github.com/akfamily/akshare) `stock_zh_a_hist`（qfq），导出后不再依赖该库。

## 纯 yoyo 复现（投票逻辑）

```bash
make research-v2        # 八股全量 v2 回测（awk，零 Python）
make research-verify-v2 # v2 锚点
make research-walk      # 五票演示
make hold-ratio         # 无问平淡 vs 急涨
make butterfly-demo     # 蝴蝶效应
```

文献锚点：`research/archive/literature_anchors.json`；解读见 `yoyo/docs/PRIOR-RESEARCH.md`。

## 为何不用 Python？

震巽股票坚持 **yoyo 三进制一条道**：

- Python = 二进制生态里的脚本层，与 React/Capacitor 同属「外部库时代」
- 实证结论已存档；逻辑验证在 `.ty` 里完成
- 全量重跑需将 CSV 行情编入 `.ty` 或扩展 yoyo 的 `50` LoadFile + 浮点 opcode（Phase 2）
