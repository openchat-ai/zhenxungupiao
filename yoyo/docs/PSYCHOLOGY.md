# 心理学与行为金融 · 震巽股票（yoyo only）

> 第 6 票 `lib/psychology.ty` → `state[15]`  
> 六票中性 sum = **6**（`params[03]`）  
> 演示：`make psychology-demo`

---

## 一、为何要把心理学纳入？

技术面（均线、RSI）假设人是理性的；真实市场里：

| 偏差 | 前人 | 市场现象 | 本仓库代理 |
|------|------|---------|-----------|
| **损失厌恶** | Kahneman & Tversky (1979) | 跌 5% 的痛苦 ≈ 涨 10% 的快乐 | 连跌 ≥2 日 → 卖票 |
| **处置效应** | Odean (1998) | 过早卖赢、过久扛亏 | 创 5 日新低 → 恐慌卖 |
| **羊群 / FOMO** | Banerjee (1992); Shiller (2019) | 连涨追高、叙事传染 | 连涨 + 5 日新高 → 买票 |
| **过度自信** | Barber & Odean (2001) | 频繁交易、高估判断力 | 见 `wuwen` 低无问 + 高振幅 |
| **锚定** | Tversky & Kahneman (1974) | 盯着买入价/前期高点 | 5 日高/低比较（`state[74]`） |

心理学票不是「读心术」，而是用**价量可观测行为**近似群体情绪。

---

## 二、第 6 票规则（`H_D2`）

```
连跌天数 >= params[09]（默认 2）     →  trit 0 卖   （损失厌恶）
收盘价 = 5 日新低                   →  trit 0 卖   （恐慌 capitulation）
连涨天数 >= params[0A]（默认 2）
  且 收盘 = 5 日新高                →  trit 2 买   （FOMO / 羊群）
否则                               →  trit 1 持   （无问 / 观望）
```

### 参数（`params.ty`）

| 槽 | 默认 | 含义 |
|----|------|------|
| `[09]` | 2 | 损失厌恶：连跌几天触发 |
| `[0A]` | 2 | FOMO：连涨几天触发 |
| `[03]` | **6** | 六票中性 Σ（全持） |

覆盖示例：

```text
30 09 03    ; 更悲观：连跌 3 日才卖
30 0A 01    ; 更易 FOMO：连涨 1 日即可
```

---

## 三、与「一涨二跌三无问」的对应

| 心理态 | 群众感受 | trit | 何时出现 |
|--------|---------|------|---------|
| 一涨 | 怕错过、兴奋 | 2 买 | FOMO 票 |
| 二跌 | 怕亏、恐慌 | 0 卖 | 损失厌恶 / 新低 |
| 三无问 | 犹豫、拖延 | 1 持 | 默认 / 多数日子 |

**众人一致买卖**：当心理学票与技术面、η 扰动**同向**时，Σ 远离 6，决策快速倒向买或卖——这是**偏差共振**，不是神秘力量。

---

## 四、输出槽位

| state | 含义 |
|-------|------|
| `[15]` | 心理学 trit |
| `[30]` | 六票中「持」个数 |
| `[31]` | 无问票占比 %（≈ count×17） |
| `[33]` | 一致风险（低无问 + 非平淡） |

---

## 五、与量化策略文档的关系

- **动量**赚的是趋势；**心理学**解释趋势为何常**过头**（FOMO / 恐慌）。
- **均值回归**赚的是过度反应；**损失厌恶**解释过度反应为何**不对称**（跌更猛）。
- 见 [`QUANT-STRATEGIES.md`](QUANT-STRATEGIES.md)、[`PRIOR-RESEARCH.md`](PRIOR-RESEARCH.md)。

---

## 六、参考文献

1. Kahneman, D., & Tversky, A. (1979). Prospect Theory. *Econometrica*.  
2. Tversky, A., & Kahneman, D. (1974). Judgment under Uncertainty: Heuristics and Biases. *Science*.  
3. Odean, T. (1998). Are Investors Reluctant to Realize Their Losses? *JF*.  
4. Barber, B. M., & Odean, T. (2001). Boys Will Be Boys. *QJE*.  
5. Banerjee, A. V. (1992). A Simple Model of Herd Behavior. *QJE*.  
6. Shiller, R. J. (2019). *Narrative Economics*.  

全量回测：`make research-v3` → `research/archive/backtest_v3_*`
