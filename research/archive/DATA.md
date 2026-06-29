# 实证数据约定

## 运行时只认三进制 `.tri`

| 文件 | 用途 |
|------|------|
| `signal_*.tri` | v2 五票：signal + next_ret |
| `flow_v5_*.tri` | v5 对照：v4 / tail / veto / ret / veto_flag |

回测与验证：

```bash
make research-v2-yoyo          # 读 signal_*.tri
make research-v5-yoyo          # 读 flow_v5_*.tri
make research-v5-tri-validate  # 校验八股 .tri + 打印汇总 JSON
```

**不解析 CSV、不调用 awk。**

## 汇总 JSON（已固化）

- `backtest_v5_tri_summary.json` — 三进制 v5 对照结论
- 历史 awk 版 `backtest_v5_compare_summary.json` 仅作对照存档

## `hist_*.csv` / `tick_*.csv` 是什么？

一次性导出的**溯源底稿**，已烘焙进 `.tri`。  
**不参与 `make research-*`**。需要刷新数据时另行约定（非 yoyo 运行时）。
