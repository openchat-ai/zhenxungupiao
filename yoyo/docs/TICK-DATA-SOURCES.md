# 逐笔成交数据来源（yoyo only 路线）

> 震巽已接入 **东方财富 push2** 当日分笔（零 Python 运行时；抓取用 curl+awk）。

---

## 一、已验证可用：东方财富 `push2`（免费、当日）

| 项 | 说明 |
|----|------|
| **接口** | `https://16.push2.eastmoney.com/api/qt/stock/details/get` |
| **参数** | `secid=市场.代码`（沪 `1.600519`，深 `0.000001`） |
| **字段** | `time,price,volume,?,bs` |
| **bs** | **1=主动买** **2=主动卖** **4=集合竞价/其他** |
| **限制** | 主要是**当日**分笔；历史逐笔需 Level-2 商用源 |
| **合规** | 研究用途；勿高频商用；遵守站点 ToS |

### 本仓库命令

```bash
make fetch-ticks          # 八股当日逐笔 → research/archive/tick_*.csv
make tick-embed CODE=600519 # 汇总主动买% → build/tick_embed.ty
make tick-demo            # 七票决策演示
```

### 单只股票

```bash
./scripts/fetch_tick_eastmoney.sh 600519 1
./scripts/fetch_tick_eastmoney.sh 000001 0
```

---

## 二、通达信 easy-tdx（历史逐笔，可选 Python）

| 项 | 说明 |
|----|------|
| **依赖** | `pip install easy-tdx`（见 `requirements-optional.txt`） |
| **命令** | `make fetch-ticks-tdx`（**仅 2026 年**，1 月 1 日~今日） |
| **输出** | `research/archive/tick_hist/tick_<code>_<YYYYMMDD>.csv` |
| **日汇总** | `tick_hist_daily.csv`（主动买/卖 %） |
| **bs 映射** | TDX `0=买→1` `1=卖→2` `2/5→4`（对齐东财格式） |
| **限制** | 依赖通达信行情服务器；**不拉更久历史**；非商用 |

与东财 `push2` 对照：

| | 东财 curl | easy-tdx |
|--|----------|----------|
| 运行时 | 零 Python | 可选 Python 抓取 |
| 历史 |  mainly 当日 | ✅ **仅 2026 年** |
| 主动买卖 | bs 1/2 | bs_flag 0/1 |

---

## 三、同花顺 / 通达信等软件

| 渠道 | 能否看逐笔 | 能否批量导出 | 适合震巽 |
|------|-----------|-------------|---------|
| 同花顺 L2 电脑版 | ✅ F1、B/S | ❌ | 人眼学习 |
| 同花顺 iFinD API | ✅ | ✅ 机构付费 | 量产回测 |
| 通达信 + probar | ✅ 含历史逐笔 | ✅ 需工具 | 个人量化 |
| 掘金 / QMT | ✅ | ✅ 券商内 | 程序化 |

---

## 四、交易所官方（机构）

- [上交所 LDDS Level-2](https://www.sseinfo.com/) — STEP/FAST 二进制流
- [深交所行情网关 MDC](http://www.szsi.cn/) — 需授权与机房

---

## 四、接入震巽决策栈

```
东财 tick CSV
    ↓ scripts/tick_to_embed.sh
state[50] 主动买占比 %
    ↓ lib/aggressive.ty 第 7 票 → state[16]
七票 Σ（中性 sum=7）→ state[22]
```

| state | 含义 |
|-------|------|
| 50 | 当日主动买笔数 % |
| 51 | 新闻情绪分 %（`news_to_embed.sh`） |
| 16 | 第 7 票 trit |
| 14 | 第 5 票 trit（价 η + `news_eta.ty`） |
| 31 | 无问票占比 % |

参数：`params[0B]=55`（买阈）、`params[0C]=45`（卖阈）

---

## 五、批量数据包 vs 一天一天下（为什么慢？）

### 直接回答

| 数据类型 | 有没有「整包下载」？ | 说明 |
|----------|---------------------|------|
| **日线 K 线** | ✅ **有** | [通达信官方「沪深京日线完整包」](https://www.tdx.com.cn/article/vipdata.html)（zip → `vipdoc`）；`easy-tdx offline sync-daily` 也可批量同步 |
| **逐笔 / L2** | ❌ **没有免费官方整包** | 通达信 zip **不含**分笔；只能走行情服务器 **一股一日一次**（我们现在用的方式） |
| **逐笔历史整包** | 💰 **商用** | 财富通/掘金/iFinD/Wind 等按月 zip、网盘或 API（机构价） |

所以：**慢不是因为八股特殊，而是逐笔这条路本来就没有「一次下完全市场」的免费包。**

### 为什么 8 股就这么久？

当前 `make fetch-ticks-tdx` 本质是：

```
请求次数 ≈ 股票数 × 交易日数
8 股 × ~115 日（2026）≈ 920 次 HTTP/通达信协议调用
```

我们实测约 **15–20 分钟**（串行 + 每次几千笔分页），折合 **~1 次/秒** 量级。

### 若推广到「全 A 股」要多久？（粗算）

| 规模 | 请求次数（2026 约 115 日） | 按 1 次/秒 | 按 10 并发 |
|------|---------------------------|-----------|-----------|
| 8 股（本仓库） | ~920 | **~15 分钟** | ~2 分钟 |
| 500 股 | ~5.8 万 | **~16 小时** | ~1.6 小时 |
| **全 A ~5000 股** | **~57 万** | **~6.6 天** | **~16 小时** |

全市场逐笔用免费 TDX 接口 **不现实**；商用 L2 包才是正道。

### 震巽项目建议（已采纳）

| 需求 | 做法 |
|------|------|
| 回测日线 | `hist_*.csv` 已固化；可用通达信 **日线 zip** 或 AKShare 一次性导出 |
| 第 7 票逐笔 | **仅 8 股 + 仅 2026 年**（`make fetch-ticks-tdx`） |
| 当日逐笔 | 东财 `curl`（秒级，八股） |
| 全市场逐笔 | **不做**（除非买 L2 数据包） |

### 商用逐笔包长什么样（参考）

典型格式（付费源）：**每月一个压缩包 → 按日文件夹 → 一股一文件 CSV**，含成交价量、委托方向等；与我们现在 `tick_<code>_<date>.csv` 目标格式一致，**买来解压进 `research/archive/` 即可**，无需一天一天 API。

---

## 六、OpenBB（可选研究工具，非运行时）

[OpenBB](https://github.com/OpenBB-finance/OpenBB) 是开源金融数据平台（Python），A 股经 **openbb-akshare** / **openbb-tushare** 扩展可拉日线、新闻、基本面。

| 对比 | 东财 push2（本仓库） | OpenBB + AKShare |
|------|---------------------|------------------|
| 运行时 | curl+awk，零 Python | 需 Python，**不进 Makefile** |
| 逐笔 bs | ✅ 当日主动买卖 | ❌ 非核心能力 |
| 日线 hist | 已固化 archive | 与 AKShare 同源，可一次性重导 |

详见 **`OPENBB.md`**。

---

## 七、诚实边界

- **日线 hist_*.csv** 仍无法区分主动买卖
- **东财当日逐笔** 可驱动「第 7 票」；**2026 逐笔** 仅八股，不全市场
- 全市场/更久逐笔需：商用 L2 数据包，或 iFinD / Wind / 掘金
- **OpenBB** 适合研究期统一导出，**不能**替代 yoyo 决策栈

---

*与 `OPENBB.md`、`PSYCHOLOGY.md`、`PRIOR-RESEARCH.md` 配套。*
