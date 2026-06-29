# 实证数据存档（零 Python）

本目录数据为 **2018–2024 A 股八股回测（archive v1，四票技术面）** 的一次性导出结果，已固化入库。  
**未含时事扰动 η 层**；v2 五票逻辑见 `yoyo/lib/perturbation.ty` 与 `make butterfly-demo`。  
**工具链不要求 Python**；读取结论只需打开 JSON/CSV，或用 yoyo 编译演示程序。

## 文件

| 文件 | 说明 |
|------|------|
| `archive/backtest_v3_summary.json` | **v3 六票+心理学**（`make research-v3`） |
| `archive/backtest_v4_summary.json` | **v4 七票+新闻 η+逐笔**（`make research-v4`） |
| `archive/backtest_v5_compare_summary.json` | **尾盘 vs 否决**（`make research-v5-compare`） |
| `archive/tick_tail_daily.csv` | 尾盘 14:30–15:00 主动买% |
| `archive/news_daily_eta.csv` | 新闻情绪日表（`make fetch-news`） |
| `archive/tick_hist/` | **2026 年**逐笔明细（`make fetch-ticks-tdx`） |
| `archive/tick_hist_daily.csv` | 历史逐笔日汇总（`make fetch-ticks-tdx`） |
| `archive/signal_*.tri` | v2 五票信号档（`make tri-archive`） |
| `archive/flow_v5_*.tri` | **v5 三版信号档**（v4/tail/veto，`make tri-archive-v5`） |
| `archive/BACKTEST_V2_REPORT.md` | v2 人类可读报告 |
| `archive/backtest_by_stock.csv` | 分标的绩效 |
| `archive/BACKTEST_REPORT.md` | 人类可读报告 |

数据来源：[AkShare](https://github.com/akfamily/akshare) `stock_zh_a_hist`（qfq），导出后不再依赖该库。

## 纯 yoyo 复现（投票逻辑）

```bash
make tri-archive-v5     # hist+tick → flow_v5_*.tri
make research-v5-tri-validate  # 三进制指标汇总（无 awk 回测）
make research-v5-yoyo   # 纯 yoyo 读 flow_v5_*.tri（单股演示，需 Wine）
make research-verify-v2 # v2 锚点
make research-walk      # 五票演示
make hold-ratio         # 无问平淡 vs 急涨
make butterfly-demo     # 蝴蝶效应
```

文献锚点：`research/archive/literature_anchors.json`；解读见 `yoyo/docs/PRIOR-RESEARCH.md`。

## 为何不用 Python？

震巽股票坚持 **yoyo 三进制一条道**：

- Python = 二进制生态里的脚本层，与 React/Capacitor 同属「外部库时代」
- 全量 v2 重算：`make research-v2`（`scripts/backtest_v2.awk` 读 `hist_*.csv`）
- 单根 K 线逻辑验证在 `.ty` 里完成（`make research-walk`）
