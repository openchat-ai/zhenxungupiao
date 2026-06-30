# 震巽股票 — 实证研究

可复现的平衡三进制策略回测，数据来自开源 [AkShare](https://github.com/akfamily/akshare)。

## 运行

```bash
pip install -r research/requirements.txt
python3 research/backtest_ternary.py
```

产出：

| 文件 | 说明 |
|------|------|
| `output/backtest_summary.json` | 汇总指标 |
| `output/backtest_by_stock.csv` | 分标的明细 |
| `output/BACKTEST_REPORT.md` | 可读报告 |

## 策略定义（与 `ternary_signal.ty` 一致）

四指标各产出 trit ∈ {−1, 0, +1}：

1. SMA(5) vs SMA(20) 符号  
2. 收盘价 vs SMA(10) 符号  
3. RSI(14)：&lt;35 → +1，&gt;65 → −1，否则 0  
4. MACD 柱符号  

`signal = sign(Σ trit)`；交易规则：+1 满仓，−1 空仓，0 维持仓位。

## 数据说明

- 标的：8 只 A 股蓝筹（2018-01-01 — 2024-12-31，前复权 qfq）
- 剔除收盘价 ≤0 或单日涨跌 &gt;50% 的异常序列
