# 用 yoyo.exe 直接编译（不用 make）

震巽默认编译器：`yoyo/compiler/yoyo.exe`。  
**make 只是薄封装**；下面每一步都可以手敲或跑 `./scripts/compile.sh`。

---

## 最快：flow 买入/卖出指示

```bash
# 1. 写入当日逐笔特征（生成 build/flow_embed.ty）
./scripts/flow_to_embed.sh research/archive/tick_features_daily.csv build/flow_embed.ty 600036

# 2. 合并源码
cat yoyo/lib/fp.ty \
    yoyo/lib/params.ty \
    yoyo/lib/flow_signal.ty \
    build/flow_embed.ty \
    yoyo/research/flow_signal_demo.ty \
  > build/flow_signal_demo.ty

# 3. 编译（Windows 本机）
yoyo/compiler/yoyo.exe build/flow_signal_demo.ty build/flow_signal_demo.exe

# Linux 无 PE 运行时，用 Wine：
# wine yoyo/compiler/yoyo.exe build/flow_signal_demo.ty build/flow_signal_demo.exe
```

或一行：

```bash
./scripts/compile.sh flow_signal
CODE=600036 ./scripts/compile.sh flow_signal
```

运行后看 **state[22]**：`0` 卖 · `1` 持 · `2` 买。

---

## 七票决策核心

```bash
cat yoyo/lib/fp.ty yoyo/lib/params.ty yoyo/lib/indicators.ty \
    yoyo/lib/perturbation.ty yoyo/lib/news_eta.ty yoyo/lib/psychology.ty \
    yoyo/lib/aggressive.ty yoyo/lib/wuwen.ty yoyo/ternary_signal.ty \
  > build/ternary_signal.ty

yoyo/compiler/yoyo.exe build/ternary_signal.ty build/ternary_signal.exe
```

```bash
./scripts/compile.sh signal
```

---

## App 主程序

```bash
cat yoyo/lib/fp.ty yoyo/lib/params.ty yoyo/lib/indicators.ty \
    yoyo/lib/perturbation.ty yoyo/lib/news_eta.ty yoyo/lib/psychology.ty \
    yoyo/lib/aggressive.ty yoyo/lib/wuwen.ty yoyo/ternary_signal.ty \
    yoyo/lib/chart.ty yoyo/stock_app.ty \
  > build/stock_app.ty

yoyo/compiler/yoyo.exe build/stock_app.ty build/stock_app.exe
```

```bash
./scripts/compile.sh stock
./scripts/compile.sh stock_gui
```

---

## 已有合并好的 .ty

```bash
yoyo/compiler/yoyo.exe build/任意合并.ty build/任意.exe
# 或
./scripts/compile.sh custom build/任意合并.ty build/任意.exe
```

---

## 和 make 的关系

| 你想做的事 | make（可选） | 直接 yoyo |
|-----------|-------------|-----------|
| flow 指示 | `make flow-signal-demo` | `./scripts/compile.sh flow_signal` |
| 决策核心 | `make signal` | `./scripts/compile.sh signal` |
| 拉逐笔数据 | `make fetch-ticks-tdx` | `./scripts/fetch_ticks_tdx_all.sh` |
| awk 回测 | `make research-v6-compare` | `./scripts/backtest_v6_compare.sh` |

**编译 yoyo 程序**：始终只需 `yoyo.exe 输入.ty 输出.exe`。  
make / compile.sh 帮你做的是 **cat 合并 lib**，不是替代编译器。
