# 震巽股票 · yoyo 路线图

## 终极目标

**纯 yoyo 手机 App**：零外部依赖，`.ty` 源码经 `yoyo.exe` 编译为 Android / iOS 原生程序。

```
yoyo/stock_app.ty  ──yoyo.exe──►  stock_app.apk / stock_app (iOS)
         ▲
         │ 自举
yoyo/compiler/yoyo.exe
```

## 阶段

### Phase 1 ✅ 整数决策核心
- `ternary_signal.ty`：4 指标 trit 投票 → 唯一买卖信号
- 官方 `yoyo.exe` 编译，无 JS / Node / npm

### Phase 2 🔄 浮点 / 定点指标（进行中）
- `lib/fp.ty`：定点四则运算（价格 × 10000）
- `lib/indicators.ty`：SMA / RSI / MACD 投票
- `docs/PHASE2-FLOAT.md`：真浮点 opcode `0x90`–`0x9F` 规范
- 待办：在 `yoyo.ty` 编译器源码中实现浮点 emitter

### Phase 3 ⬜ 多目标后端
- ELF64（Linux / Android）
- Mach-O（iOS / macOS）
- 同一 `.ty`，切换 `--target` 参数

### Phase 4 ⬜ GUI 与手机壳
- 帧缓冲绘制 opcode（K 线、指标子图）
- 触摸输入 opcode
- 紫色买入 / 绿色卖出信号渲染

## 不允许的依赖

- ❌ React / Vue / Capacitor
- ❌ Node.js 运行时（仅 bootstrap 阶段可用，最终退役）
- ❌ npm 第三方包
- ❌ CRT / libc（产物直接 syscall）

## 构建

```bash
make              # 合并 .ty 模块 → build/stock_app.exe
make signal       # 仅编译决策核心
```

Windows 直接运行 `yoyo.exe`；Linux/macOS 需 Wine。
