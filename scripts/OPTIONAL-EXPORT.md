# 可选数据刷新（不进 yoyo 回测）

以下脚本仅用于**从外部拉新底稿**，不参与 `make research-*`：

| 脚本 | 输出 | 说明 |
|------|------|------|
| `fetch_ticks_tdx_all.sh` | `tick_hist/*.csv` | 需 Python easy-tdx |
| `tick_hist_to_daily.sh` | `tick_hist_daily.csv` | 内部用 shell 聚合 |
| `fetch_news_all.sh` | `news_daily_eta.csv` | 需 Python |
| `news_to_eta_daily.awk` | 同上 | 仅 fetch 链调用 |

刷新后须**人工重烘焙** `signal_*.tri` / `flow_v5_*.tri`（当前仓库已固化，无自动导出器）。

**实证主路径**：`research/archive/*.tri` + `make research-v5-tri-validate`
