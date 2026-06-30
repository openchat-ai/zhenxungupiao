# 震巽股票

纯 **yoyo** 手机 App 路线：零外部依赖，`.ty` → 原生程序。

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

《[三进制与股票预测的玄学关系](yoyo/docs/THEORY-TERNARY-METAPHYSICS.md)》——震巽、平衡三进制 (−1,0,+1)、四指标投票与易经象数的对应。

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
