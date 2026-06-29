# 实证数据存档

**运行时只认三进制 `.tri`**，见 [`archive/DATA.md`](archive/DATA.md)。

## 文件

| 文件 | 说明 |
|------|------|
| `archive/signal_*.tri` | v2 五票：signal + next_ret |
| `archive/flow_v5_*.tri` | v5 对照：v4 / tail / veto / ret / veto_flag |
| `archive/backtest_v5_tri_summary.json` | v5 三进制汇总（固化） |
| `archive/BACKTEST_V5_TRI_REPORT.md` | v5 人类可读报告 |

`hist_*.csv`、`tick_*.csv` 等为**溯源底稿**，不参与 `make research-*`。

## 纯 yoyo 复现

```bash
make verify-tri-v5           # 校验八股 flow_v5_*.tri
make research-v5-tri-validate  # 校验 + 打印汇总 JSON
make research-v5-yoyo          # 单股 yoyo 回测（CODE=600519）
make research-v2-yoyo          # v2 五票演示
make research-walk
make butterfly-demo
```

## 为何不用 CSV / awk？

震巽股票坚持 **yoyo 三进制一条道**：

- 实证信号已烘焙进 `.tri` 字节档
- 回测 = `LoadFile` + `tri_io.ty` 读 trit
- CSV 仅保留作数据来源证明，**不回灌运行时**

可选数据刷新（不进回测主路径）：`make fetch-ticks-tdx`、`make fetch-news`
