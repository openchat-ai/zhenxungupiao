# 震巽股票

纯 **yoyo** 手机 App 路线：零外部依赖，`.ty` → 原生程序。

## 结论一览（先看这个）

**[`结论.md`](结论.md)** — 核心结论、实证数字、以及「众人为何一致买卖、三进制能否解释」的直答。

| 要点 | 结论 |
|------|------|
| 个人三态 | 涨(买) / 跌(卖) / 无问(持) → trit 2 / 0 / 1 |
| 众人一致 | 信息 + 价格反馈 + 制度耦合的**涌现**，不是神秘统一意志 |
| 三进制角色 | 描述**如何表决**，不能预言集体狂飙 |
| A 股回测 | Sharpe 0.30 &gt; 二元 0.20，但 **corr(信号,次日)≈0.003** |
| 工具链 | 仅 `yoyo.exe`，无 Python / npm |
| 无问占比 | `state[31]`；全量曲线 `make research-v2` |
| v3 心理学 | `make psychology-demo` |
| **逐笔第 7 票** | `make fetch-ticks` → `make tick-demo`（东财当日分笔） |

## 三阶段进展

1. **浮点** — 编译器补丁 `0x91` FADD、`0x98` I2F、`0x97` F2I、`0x95` FCMP
2. **ELF64** — `A2 01` 切换 Linux/Android 产物格式
3. **GUI** — `chart.ty` K 线 + 指标条，**紫 `#a855f7` 买 / 绿 `#2ebd85` 卖**

## 快速构建

```bash
make stock-gui      # build/stock_gui.exe（PE）
make bootstrap      # 生成含补丁的 yoyo_next.exe
make stock-gui-elf  # ELF 版
```

Linux 需 Wine 运行 `yoyo.exe`。

## 理论

- **[结论一览（推荐先读）](结论.md)** — 实证数字 + 集体一致 + 无问占比参数  
- **[前人研究与参数依据](yoyo/docs/PRIOR-RESEARCH.md)** — Fama / Banerjee / Barber-Odean 等  
- **[经典量化策略](yoyo/docs/QUANT-STRATEGIES.md)** — 动量 / 均值回归为何能赚钱  
- **[逐笔数据来源](yoyo/docs/TICK-DATA-SOURCES.md)** — 东财 push2 已接入，`make fetch-ticks`
- 《[三进制与股票预测](yoyo/docs/THEORY-TERNARY-METAPHYSICS.md)》——完整推导  
- 存档：`research/archive/`；验证：`make hold-ratio`、`make research-walk`

## 目录

```
yoyo/
  compiler/yoyo.ty          编译器源码（yoyo-ide）
  compiler/patches/         Phase 2/3/4 补丁
  lib/chart.ty              GUI 渲染
  stock_gui.ty              GUI 主程序
  stock_app.ty              无 GUI 版
scripts/merge_compiler.sh   合并补丁
Makefile
```

详见 `yoyo/docs/ROADMAP.md`。
