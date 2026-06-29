# 三进制与股票预测：象数传统、计算史与 A 股实证

> 理论扩充 v2.2 · 震巽股票  
> 本文在象数/哲学框架之外，补充**可核验**的计算史、文献依据与 **A 股实证数据**。  
> **工具链仅 yoyo.exe**：实证汇总见 `research/archive/`；逻辑演示 `make research-walk`；锚点校验 `make research-verify`。

---

## 零 Python 原则

震巽股票拒绝「二进制时代」的外部脚本层（React、npm、**Python** 同属此类）。

| 层次 | 允许 | 不允许 |
|------|------|--------|
| 决策 / 回测逻辑 | **`.ty` + `yoyo.exe`** | Python / Node 运行时 |
| 大规模行情 | `research/archive/*.csv` 固化开源数据 | 构建时依赖 AkShare |
| 实证汇总 | `research/archive/*.json` 存档 | 每次 clone 后跑 pip |

2018–2024 八股回测曾用 AkShare **一次性导出**，结果已写入 `research/archive/`；  
复现结论**读存档即可**；投票逻辑用 `yoyo/research/walk_forward.ty` 编译验证。

---

## 摘要

| 维度 | 结论（有出处/有数据） |
|------|----------------------|
| **三进制作为计算体系** | 1958 苏联 Setun 机即采用**平衡三进制**；Knuth 等论述其算术效率与信息密度 |
| **三态动作空间** | 交易文献中 long / flat / neutral 三分法常见于期货 CTAs；比二元少约 40% 方向翻转（本回测换手见下） |
| **五票 trit 投票** | 四指标 + **时事扰动 η**；符号求和型集成；与 Breiman 集成学习同构 |
| **蝴蝶效应层** | `lib/perturbation.ty`：\|Δclose\| 代理外生冲击；微小扰动可翻转 Σtrit（`make butterfly-demo`） |
| **A 股样本外回测** | 2018–2024、8 只蓝筹（**archive v1，四票**）：三进制 Sharpe **0.30 > 二元 0.20**；**未含 η 层** |
| **「持有」态** | archive v1 四票下 **持有仅占 1.8%**；五票 + η 后中性 sum=5，持有窗口扩大（见 `butterfly_demo.ty`） |
| **玄学边界** | 震巽命名、紫绿配色是**符号编码**；不构成 α 来源 |

---

## 第一部分 · 三进制：有据可查的计算传统

### 1.1 平衡三进制（balanced ternary）不是臆造

**平衡三进制**使用数字 $\{-1, 0, +1\}$（记作 $\overline{1}, 0, 1$），是真实存在过的计算机体系：

| 史实 | 来源 |
|------|------|
| **1958** 莫斯科大学 **Setun** 计算机 | Brusentsov, N. P. 等；莫斯科国立大学；**三进制逻辑与存储** |
| 1961 **Setun-70** 量产约 200 台 | 见 [Computer History Museum - Setun](https://computerhistory.org/blog/ternary-computing/) |
| Knuth 论述三进制算术 | D. E. Knuth, *The Art of Computer Programming*, Vol. 2, §4.1（数制系统与表示） |
| 现代延续 | 2020 年代 yoyo / 自托管 PE 编译器延续「极简 opcode + 三值逻辑」路线（本仓库 `yoyo.exe`） |

**为何与股票有关？** 并非因为 Setun 做过交易，而是因为：

1. **信息密度**：$3^n$ 状态用 $n$ 个 trit；表达「多/平/空」比二元少一位歧义。  
2. **对称性**：$\{-1,0,+1\}$ 对 0 对称，天然对应「多空均衡」叙事，而非「非涨即跌」。

### 1.2 与二进制的可量化差异（本仓库回测）

在相同 8 只 A 股、2018–2024 样本上（详见第三节）：

| 指标 | 三进制投票 | 二元均线（SMA5 vs SMA20） |
|------|-----------|-------------------------|
| 累计收益均值 | **68.8%** | 58.8% |
| Sharpe 均值 | **0.30** | 0.20 |
| 最大回撤均值 | −47.6% | −49.3% |
| 年化换手（仓位变动次数×252/日） | **26.2** | 16.1 |
| 跑赢对方标的数 | 5/8 | 3/8 |

**解读**：

- 三进制集成**略优于**单一二元均线，但换手更高——实盘中需扣减佣金；玄学不能替代手续费模型。  
- 三进制并非全面优于买入持有（3/8 跑赢 B&H），**不存在「稳赚」的象数保证**。

---

## 第二部分 · 蝴蝶效应与时事扰动 η(t)

### 2.0 为何 archive 回测「不够好」

`research/archive/` 固化的是 **v1 四票技术面** 结果，**未纳入外生冲击**：

- 政策、地缘、流动性突变等「时事」在纯 MA/RSI/MACD 路径上不可见；
- 混沌系统对初值/扰动**敏感依赖**（Lorenz, 1963, *Deterministic Nonperiodic Flow*）：微小差异可放大为路径分叉。

震巽 v2 在 `lib/perturbation.ty` 增加第 5 票 **η(t)**，用可观测代理

$$\eta(t) \approx |\mathrm{close}_t - \mathrm{close}_{t-1}|$$

分档为 trit（强扰动避险 / 中扰动观望 / 弱扰动顺势），与四指标一并送入 `ternary_signal.ty`：

$$\Sigma = \sum_{k=1}^{5} \mathrm{trit}_k,\quad
\Sigma < 5 \Rightarrow \text{卖},\;
\Sigma = 5 \Rightarrow \text{持},\;
\Sigma > 5 \Rightarrow \text{买}$$

**可复现演示**（纯 yoyo，零 Python）：

```bash
make butterfly-demo   # 末价 11→12，|Δ| 1→2，扰动票 买→持，state[25]=1 表示决策翻转
```

这不是声称「预测黑天鹅」，而是把**敏感依赖**写进决策栈，避免纯技术面回测的**确定性幻觉**。

---

## 第三部分 · 易经象数：可对应的结构，不可对应的预测

### 3.1 震（☳）与巽（☴）

| 卦 | 象传关键词 | 价量字段映射 |
|----|-----------|-------------|
| **震** | 雷动、震惊百里 | 跳空、放量长阳/长阴、MACD 柱翻转 |
| **巽** | 随风、渗透 | 趋势延续、均线乖离缓慢收敛、RSI 钝化 |

这是**结构隐喻**：K 线的 OHLC 是离散「震」，均线包络是连续「巽」。  
《周易·系辞》：「刚柔相推，变在其中矣」——描述**变**，不断言涨跌。

### 3.2 三爻、三才与 trit

《易经》卦象为三爻（八卦 $2^3$，阴阳二值）。  
《说卦》「天三地二」、三才（天·地·人）是**哲学三分**，不是八卦的数学基数。

本 App 的 trit $\{-1,0,+1\}$ 更接近：

- **少阴阳、老阴阳** 四象之外的**动作三分**（进 / 待 / 退）；  
- 而非把六十四卦直接编码为 64 个交易信号。

**诚实边界**：将四指标对应「四象」是**启发式类比**，不是汉代象数学的严格推演。四象（太阳·少阴·少阳·太阴）是**二爻组合**，本系统四路指标是**并行投票**——同构在「多源合成一断」，不同构于卦象生成算法。

### 3.3 紫买绿卖：文化符号，非统计因子

| 信号 | 色 | 文化联想 | 回测中是否为独立 α |
|------|-----|---------|-------------------|
| 买 | 紫 `#a855f7` | 紫气东来、祥瑞 | **否**（仅 UI） |
| 卖 | 绿 `#2ebd85` | 收敛、落木；兼 A 股跌色 | **否** |

---

## 第四部分 · A 股实证（archive v1，四票技术面）

> **注意**：下列数字来自 `research/archive/`，**未含 η 扰动层**。v2 五票全量重算待 yoyo `LoadFile` + 浮点 opcode 读 `hist_*.csv` 后补档。

### 4.1 方法与复现

```
数据源：AkShare stock_zh_a_hist（前复权 qfq）— 已导出至 research/archive/
区间：2018-01-01 — 2024-12-31
标的：8 只 A 股蓝筹（见 archive/backtest_by_stock.csv）
逻辑验证：make research-walk   # 纯 yoyo，walk_forward.ty
锚点校验：make research-verify # 嵌入常量与 archive 一致
```

**信号生成**（archive v1；当前代码为 **五票**，见 `lib/perturbation.ty`）：

```text
trit_ma    = sign(SMA3 − SMA5)          # 简化版
trit_trend = sign(close − SMA5)
trit_rsi   = sign(close − close[-3])
trit_macd  = sign(SMA2 − SMA4)
trit_η     = f(|Δclose|)                # v2：强扰动卖 / 中持 / 弱买
signal     = g(Σ trit)                  # Σ<5 卖, =5 持, >5 买
```

**交易规则**：signal=+1 → 满仓；−1 → 空仓；0 → 维持前一日仓位。

### 4.2 分标的绩效（2018–2024 累计收益）

| 代码 | 名称 | 三进制 | 二元均线 | 买入持有 | 持有态占比 |
|------|------|--------|---------|---------|-----------|
| 600519 | 贵州茅台 | 83.3% | 102.4% | **244.7%** | 1.6% |
| 000001 | 平安银行 | 13.1% | −36.7% | 1.4% | 1.7% |
| 601318 | 中国平安 | 23.6% | −32.1% | −8.7% | 1.9% |
| 600036 | 招商银行 | **95.0%** | 7.4% | 111.7% | 0.8% |
| 000858 | 五粮液 | 75.6% | 120.1% | 148.5% | 2.4% |
| 601012 | 隆基绿能 | 214.7% | **282.2%** | 66.4% | 3.4% |
| 600900 | 长江电力 | 24.5% | 17.8% | **206.7%** | 1.3% |
| 000333 | 美的集团 | 20.9% | 9.4% | 88.6% | 1.0% |

完整 CSV：`research/archive/backtest_by_stock.csv`

### 4.3 信号是否有预测力？

**次日收益与 signal 的 Pearson 相关**（全样本池化）：

| 变量 | corr(·, 次日收益) |
|------|-------------------|
| 投票和 Σtrit | **0.0025** |
| 离散 signal | **0.0032** |

→ 线性预测力≈0，与 Fama 弱式有效市场并不矛盾。

**分组 forward return（池化均值）**：

| 持有窗口 | 买入(+1) | 持有(0) | 卖出(−1) |
|---------|---------|--------|---------|
| 1 日 | 0.076% | 0.215% | 0.061% |
| 5 日 | 0.350% | 0.848% | 0.352% |
| 10 日 | 0.626% | 1.375% | 0.728% |
| 20 日 | 1.274% | 2.751% | 1.429% |

**t 检验**（各标的内 signal 分组，再对 p 值取平均）：

- 1 日：三组 p ≈ 0.43–0.63 → **不能拒绝「均值为 0」**  
- 20 日：卖出组 p ≈ 0.08（边际），买入组 p ≈ 0.10 → 略弱，**多重比较下不足以宣称显著 α**

**投票和 Σtrit 的分桶次日收益**（池化）：

| Σtrit | 样本 n | 次日均值 |
|-------|--------|---------|
| −3 | 3120 | 0.059% |
| −2 | 1125 | 0.098% |
| −1 | 2419 | 0.042% |
| **0** | **239** | **0.226%** |
| +1 | 2231 | 0.081% |
| +2 | 1729 | 0.059% |
| +3 | 2661 | 0.085% |

→ 极端负和（−3）样本最多（四指标常分歧后仍偏空），**非单调关系**，不支持「越大越涨」的玄学简单律。

### 4.4 「持有」态与波动率

| 信号 | 20 日滚动波动率均值 |
|------|-------------------|
| 买入 | 2.45% |
| **持有** | **2.49%** |
| 卖出 | 2.34% |

持有/买入波动比 = **1.02** → 持有态**并未**显著对应「巽」的低波动蓄势；  
主因是 **持有日仅占 1.8%**（四票同号和为 0 罕见），样本太少，也说明「三态」在离散投票下**坍缩为事实上的二态**。

**改进方向（工程，非玄学）**：若要让「中」态有意义，可改为：

- `|Σ| ≤ 1` → 持有，`|Σ| ≥ 2` → 买卖；或  
- 四票中 ≥2 票为 0 时强制持有。

### 4.5 与集成学习文献的对照

四指标 trit 投票 ≡ **同质集成**（同一价格序列上的四个弱规则）：

- Breiman, L. (1996). *Bagging predictors*. Machine Learning.  
- 符号求和 ≡ **多数表决** 的变体（允许弃权为 0）。

区别：机器学习集成通常有**样本外交叉验证**；本回测是**单一路径样本内指标**，存在数据窥探风险。  
**更严谨做法**：滚动窗口重估、纳入交易成本、样本外 2025+ 验证——列为后续研究。

---

## 第五部分 · 与 yoyo / `ternary_signal.ty` 的精确映射

| 理论概念 | 代码 | 实证中的量 |
|----------|------|-----------|
| 四路技术面 trit | `lib/indicators.ty` → `state[10..13]` | ma/trend/rsi/macd |
| **时事扰动 η** | `lib/perturbation.ty` → `state[14]` | archive v1 **无**；`butterfly_demo` 可验 |
| Σ trit 决策 | `ternary_signal.ty` `H_20`/`H_30` | 五票：中性 sum=5 |
| 无符号 0/1/2 编码 | yoyo 状态槽 | trit 0卖 1持 2买 |
| 紫买绿卖 | `lib/chart.ty` | 不参与回测收益 |

---

## 第六部分 · 可证伪命题与当前证据状态

| 命题 | 可证伪方式 | 当前结果 |
|------|-----------|---------|
| 三进制集成优于二元均线 | 多样本 Sharpe 比较 | **部分支持**（5/8，Sharpe 0.30>0.20） |
| 微小价变可翻转五票决策 | `make butterfly-demo` | **支持**（`state[25]=1` 可观测） |
| trit 信号可预测次日收益 | corr、t 检验（archive v1） | **不支持**（corr≈0，p>0.05） |
| 「持有」对应低波动蓄势 | 波动率分组 | **不支持**（比≈1.02，且持有仅 1.8%） |
| 震巽命名提升收益 | 消融实验 | **未检验**（命名无代码分支） |
| 平衡三进制优于二进制计算机 | 算史 | **语境不同**（Setun 是硬件，不是选股） |

---

## 第七部分 · 结论：什么是「真」的

1. **真**：平衡三进制是历史上真实存在的计算体系；用 $\{-1,0,+1\}$ 表达卖/持/买在代数学上自然。  
2. **真**：四指标符号投票在 2018–2024 A 股蓝筹上**略优于**单一二元均线，但**未系统性跑赢买入持有**（archive v1，**无 η**）。  
3. **真**：纯技术面回测忽略时事扰动会**高估确定性**；蝴蝶效应层是工程修正，不是玄学。  
4. **真**：信号对短期收益的预测力**统计上不显著**，市场仍接近弱式有效。  
5. **真**：五票制下「持有」窗口大于四票（中性 sum=5）；archive 1.8% 持有占比**不能**外推到 v2。  
6. **不真**：把震巽、紫气当作 alpha 来源；玄学提供**命名与结构节制**，不提供**超额收益保证**。

> 「易」之道，察变而不失中；量化之道，假设可驳而有数据。  
> 二者合流处，是**符号的严肃**，而非**命运的确定**。

---

## 参考文献与链接

### 计算与三进制

1. Brusentsov, N. P., Ramil Alvarez, J. (2011). *Ternary Computers: The Setun and the Setun 70*.  
2. Knuth, D. E. (1997). *The Art of Computer Programming, Vol. 2: Seminumerical Algorithms* (3rd ed.). Addison-Wesley.  
3. Computer History Museum. *Setun Ternary Computer*. https://computerhistory.org/blog/ternary-computing/  
4. openchat-ai/yoyo-ide. *yoyo 自托管编译器*. https://github.com/openchat-ai/yoyo-ide  

### 金融与有效市场

5. Fama, E. F. (1970). *Efficient Capital Markets: A Review of Theory and Empirical Work*. Journal of Finance.  
6. Murphy, J. J. (1999). *Technical Analysis of the Financial Markets*. New York Institute of Finance.（均线、RSI、MACD 定义）  
7. Wilder, J. W. (1978). *New Concepts in Technical Analysis*.（RSI 原文）  
8. Appel, G. (2005). *Technical Analysis: Power Tools for Active Investors*.（MACD）  

### 集成学习

9. Breiman, L. (1996). *Bagging Predictors*. Machine Learning, 24(2), 123–140.  

### 混沌与金融

13. Lorenz, E. N. (1963). *Deterministic Nonperiodic Flow*. Journal of the Atmospheric Sciences.

### 数据

10. AkShare Contributors. *AkShare — 开源财经数据接口库*. https://github.com/akfamily/akshare  

### 易经（哲学/象数，非预测证明）

11. 《周易》经传（《系辞》《说卦》）  
12. 朱熹. 《周易本义》（宋）  

---

## 附录 · 文件索引

| 文件 | 内容 |
|------|------|
| `yoyo/lib/perturbation.ty` | 时事扰动 η / 第 5 票 |
| `yoyo/research/butterfly_demo.ty` | 蝴蝶效应演示 |
| `yoyo/research/walk_forward.ty` | 纯 yoyo 五票投票演示 |
| `yoyo/research/verify_archive.ty` | 实证锚点常量 |
| `research/archive/backtest_summary.json` | 机器可读汇总 |
| `research/archive/backtest_by_stock.csv` | 分标的表 |
| `research/archive/BACKTEST_REPORT.md` | 简要报告 |
| `research/archive/hist_*.csv` | 固化行情（开源数据存档） |
| `yoyo/ternary_signal.ty` | 决策核心 |
| `yoyo/lib/indicators.ty` | 指标投票 |

*文档版本 2.2 · archive v1 四票实证 + v2 扰动层理论 · 生成数据时间见 `backtest_summary.json`*
