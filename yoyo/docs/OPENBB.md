# OpenBB 调研（与震巽 yoyo-only 路线对照）

> [OpenBB](https://github.com/OpenBB-finance/OpenBB) 是开源金融数据平台（约 7 万 star），面向分析师、量化与 AI Agent。  
> **结论先行**：适合作**可选的研究期数据导出器**（日线/新闻/基本面）；**不适合**作为震巽运行时依赖；**逐笔 L2 不是其强项**——本仓库仍以东财 `curl+awk` 抓当日分笔为主。

---

## 一、OpenBB 是什么

| 组件 | 说明 |
|------|------|
| **Open Data Platform (ODP)** | 开源后端：`pip install openbb`，Python API + CLI |
| **OpenBB Workspace** | 企业级前端仪表盘（可接自定义后端） |
| **Provider 框架** | 统一接口 `obb.equity.price.historical(...)`，可换数据源 |
| **MCP / REST** | 可把数据暴露给 AI Agent（与本项目「决策在 yoyo」无直接耦合） |

典型调用（需 Python 3.11+）：

```python
from openbb import obb

df = obb.equity.price.historical(
    symbol="600519",
    start_date="2020-01-01",
    end_date="2024-12-31",
    provider="akshare",   # 或 tushare
).to_dataframe()
```

安装社区 A 股扩展后需重建：

```bash
pip install openbb openbb-akshare   # 或 openbb-tushare
python -c "import openbb; openbb.build()"
```

官方博客：[Extending OpenBB for A-Share and Hong Kong Stock Analysis](https://openbb.co/blog/extending-openbb-for-a-share-and-hong-kong-stock-analysis-with-akshare-and-tushare/)

---

## 二、A 股相关扩展

| 包 | PyPI | 数据源 | 特点 |
|----|------|--------|------|
| **openbb-akshare** | [pypi](https://pypi.org/project/openbb-akshare/) | [AKShare](https://github.com/akfamily/akshare) | 免费；聚合东财/新浪/腾讯等；社区活跃 |
| **openbb-tushare** | [pypi](https://pypi.org/project/openbb-tushare/) | [Tushare](https://tushare.pro/) | 免费版有限；Pro 需积分；数据更规范 |
| **openbb-hka** | Workspace 应用 | 上两者 | A 股/港股预置仪表盘模板 |

AKShare 底层与本仓库 `research/archive/hist_*.csv` 的来源（`stock_zh_a_hist` qfq）**同源**——OpenBB 只是换了一层统一 API，**不增加新 α**。

---

## 三、能力对照：震巽需要什么 vs OpenBB 能给什么

| 需求 | 震巽现状 | OpenBB + A 股扩展 | 评价 |
|------|---------|-------------------|------|
| **日线 OHLCV 2018–24** | `hist_*.csv` 已固化 | ✅ `equity.price.historical` | 可替代一次性导出，运行时不必保留 Python |
| **当日逐笔 + 主动买卖 bs** | `scripts/fetch_tick_eastmoney.sh` | ⚠️ 非 OpenBB 核心；AKShare 有 `stock_zh_a_tick_*` 但未进 openbb-akshare 主文档 | **继续用东财 push2** |
| **历史逐笔全样本** | ❌ 缺 | ❌ 需 TDX / iFinD / 掘金 L2 | OpenBB 帮不上 |
| **新闻/时事 η 层** | `perturbation.ty` 用日涨跌幅代理 | ✅ `obb.news.company(..., provider="akshare")` | 可作 η 增强的**离线语料**，需另写 NLP→扰动 |
| **基本面/财报** | 未接入 | ✅ AKShare/Tushare 经 OpenBB | 未来扩展票时可参考 |
| **运行时零依赖** | ✅ 仅 `yoyo.exe` | ❌ 强依赖 Python 生态 | **禁止进 Makefile 主路径** |

---

## 四、与同花顺 / 东财直抓的关系

```
                    ┌─────────────────┐
  研究期（可选）     │ OpenBB+AKShare  │──→ hist_*.csv / news.json
                    └────────┬────────┘
                             │ 一次性导出
                             ▼
                    ┌─────────────────┐
  研究期（已用）     │ curl 东财 push2 │──→ tick_*.csv（当日 bs）
                    └────────┬────────┘
                             │ 固化进 archive
                             ▼
                    ┌─────────────────┐
  运行时（必须）     │ yoyo .ty 七票   │──→ state[22] 决策
                    └─────────────────┘
```

- **同花顺**：人眼看 L2、F1 分笔；**无开放批量 API**（iFinD 机构付费另说）→ 见 `TICK-DATA-SOURCES.md`
- **东财 push2**：免费、当日、含 `bs` 主动买卖标记 → **第 7 票已接入**
- **OpenBB**：统一「研究笔记本」入口；对震巽而言 ≈ **包装过的 AKShare**，价值在**多市场统一接口**和 **Workspace 可视化**，不在运行时

---

## 五、若要用 OpenBB 导出（可选，非仓库默认）

**本仓库已实现**（AKShare 直连，与 OpenBB `provider=akshare` 同源）：

```bash
pip install -r requirements-optional.txt
make fetch-news              # → research/archive/news_*.csv + news_daily_eta.csv
make extend-hist             # 延伸 hist_*.csv 至今日
python3 scripts/export_news_optional.py --openbb   # 需配置 akshare_api_key
```

η 层接入：`yoyo/lib/news_eta.ty`（读 `state[51]`）· `make news-demo`

---

## 六、原 OpenBB 手工导出示例

以下**不在 CI/Makefile 中执行**；导出后 CSV 入 `research/archive/`，与现有 `hist_*.csv` 格式对齐即可。

```python
# 一次性脚本示例（开发者本机，非震巽运行时）
from openbb import obb
import pandas as pd

STOCKS = ["600519", "000001", "601318", "600036", "000858", "601012", "600900", "000333"]
for code in STOCKS:
    df = obb.equity.price.historical(
        symbol=code, start_date="2018-01-01", end_date="2024-12-31", provider="akshare"
    ).to_dataframe()
    # 列名对齐 archive：date,open,close,high,low,volume
    df.to_csv(f"research/archive/hist_{code}.csv", index=False)
```

逐笔若走 AKShare 原生（不经 OpenBB 文档化接口）：

```python
import akshare as ak
# 腾讯源历史分笔；字段与东财 push2 不同，需 awk 清洗
df = ak.stock_zh_a_tick_tx(symbol="sh600519", trade_date="20240628")
```

历史分笔更稳妥路线仍是 **通达信协议**（如 easy_tdx / mootdx），见 `TICK-DATA-SOURCES.md` 第二节。

---

## 七、诚实结论（给决策用）

1. **OpenBB 值得知道**：全球开源金融数据「枢纽」，A 股靠社区扩展已可用。
2. **不值得搬进震巽运行时**：与「零 Python / 零 npm」原则冲突；和已删的 React 同属外部生态。
3. **对当前七票栈**：
   - 日线回测：archive 已有，OpenBB **无增量**
   - 第 7 票逐笔：东财 curl **更直接**；OpenBB 未标准化逐笔 provider
   - 未来 η 新闻层：OpenBB `news` **可考虑**作离线语料，仍须固化 CSV/JSON 后进 yoyo
4. **若你已在用 OpenBB Workspace**：可把震巽 `backtest_v*_summary.json` 当自定义 widget 数据源；方向是「震巽 → OpenBB 展示」，不是反过来依赖 OpenBB 决策。

---

## 七、链接

| 资源 | URL |
|------|-----|
| OpenBB 主仓 | https://github.com/OpenBB-finance/OpenBB |
| openbb-akshare | https://github.com/finanalyzer/openbb_akshare |
| A 股扩展官方文 | https://openbb.co/blog/extending-openbb-for-a-share-and-hong-kong-stock-analysis-with-akshare-and-tushare/ |
| 本仓库逐笔路线 | `TICK-DATA-SOURCES.md` |
| 本仓库结论入口 | 仓库根 `结论.md` |

---

*调研日期：2026-06；与 `PRIOR-RESEARCH.md`、`QUANT-STRATEGIES.md` 配套。*
