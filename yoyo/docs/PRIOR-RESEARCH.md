# 前人研究成果 · 震巽股票参数依据

> 纯文档索引；可调参数在 `yoyo/lib/params.ty`，无问占比在 `yoyo/lib/wuwen.ty`。  
> 机器可读锚点：`research/archive/literature_anchors.json`。

---

## 一、为何加「无问占比」

| 观察 | 前人结论 | 本仓库用法 |
|------|---------|-----------|
| 多数人常常不交易 | Odean (1998)：处置效应下仍大量账户低频交易 | `state[31]` 五票中持(1)占比 % |
| 看得见的成交≠所有人 | Barber & Odean (2000)：过度交易损害收益 | 对比 archive **1.8%** 策略持有日 |
| 一致买卖是涌现 | Banerjee (1992) 信息瀑布；LSV (1992) 机构羊群 | `state[33]` 低无问+高振幅 → 一致风险 |
| 叙事可同步情绪 | Shiller (2019) *Narrative Economics* | η 时事扰动层 `perturbation.ty` |
| 小扰动大分叉 | Lorenz (1963) 混沌 | `make butterfly-demo` |
| 技术信号难预测 | Fama (1970) 弱式有效 | archive corr≈**0.003** |
| 跌比涨更一致 | Kahneman & Tversky (1979) 前景理论 | 强扰动默认卖票 |

---

## 二、参数槽 `params.ty`（state[01..08]）

| 槽 | 默认 | 含义 | 文献/实证依据 |
|----|------|------|--------------|
| `[01]` | 3 | η 强扰动 \|Δ\|≥ | 政策/跳空代理；可调灵敏度 |
| `[02]` | 2 | η 中扰动 \|Δ\|≥ | 蝴蝶演示：1→2 即翻转 |
| `[03]` | 5 | Σ 中性 sum | 五票全持(1)×5 |
| `[04]` | 1 | 平淡市 \|Δ\|≤ | 低活动 ≈ 多无问（Odean 低频） |
| `[05]` | 2 | 低无问警戒：持票数≤ | LSV/Banerjee：少观望+大振幅→羊群 |
| `[06]` | 6 | 买阈 sum>[03] | 与 [03] 联动 |
| `[07]` | 12 | archive 持有日%×10 | **1.8%** → `backtest_summary.json` |
| `[08]` | 46 | 低换手账户% 锚 | 中证登口径约 **46%**（见 anchors JSON） |

修改示例（在入口 `.ty` 顶部覆盖）：

```text
30 01 04    ; 提高强扰动门槛
30 05 01    ; 更严：仅 0–1 票无问即警戒
```

---

## 三、无问占比输出 `wuwen.ty`（H_D1）

| 输出 | 含义 |
|------|------|
| `state[30]` | 五票中持(1)个数 0–5 |
| `state[31]` | **无问票占比 %**（0–100） |
| `state[32]` | 市场平淡 1/0（\|Δ\|≤[04]） |
| `state[33]` | **一致风险** 1/0（持票≤[05] 且 非平淡） |

```bash
make hold-ratio    # 平淡 vs 急涨两场景对照
```

---

## 四、关键数字对照

| 指标 | 我们的 archive | 文献/市场 |
|------|---------------|----------|
| 策略「持有」交易日 | **1.8%** | 远低于真实账户「无问」比例 |
| 五票无问票%（平淡市演示） | **~60%** | 单根 K 线上多指标常给「持」 |
| 五票无问票%（急涨演示） | **~20%** | 振幅放大→一致风险↑ |
| corr(信号,次日收益) | **0.003** | Fama 弱式有效 |

> **要点**：archive 的 1.8% 是**策略仓位持有日**，不是**人群无问比例**。  
> 五票 `state[31]` 才是「这一根 K 线上，多少路信号在喊无问」。

---

## 五、参考文献（简目）

1. Fama, E. F. (1970). Efficient Capital Markets. *Journal of Finance*.  
2. Banerjee, A. V. (1992). A Simple Model of Herd Behavior. *QJE*.  
3. Lakonishok, J., Shleifer, A., Vishny, R. (1992). The Impact of Institutional Trading on Stock Prices. *JFE*.  
4. Odean, T. (1998). Are Investors Reluctant to Realize Their Losses? *JF*.  
5. Barber, B. M., Odean, T. (2000). Trading Is Hazardous to Your Wealth. *JF*.  
6. Kahneman, D., Tversky, A. (1979). Prospect Theory. *Econometrica*.  
7. Shiller, R. J. (2019). *Narrative Economics*. Princeton.  
8. Lorenz, E. N. (1963). Deterministic Nonperiodic Flow. *JAS*.  
9. Breiman, L. (1996). Bagging Predictors. *Machine Learning*.（集成投票）  
10. 中国证券登记结算公司. 投资者统计月报（账户结构、换手）.

---

*与 `结论.md`、`THEORY-TERNARY-METAPHYSICS.md` 配套使用。*
