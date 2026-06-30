# yoyo 三进制编译器 (yoyo.exe)

本目录存放 [openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) 官方 bootstrap 产物
`build/yoyo.exe`（PE32+ x86_64，约 85 KB）。

**这是真正的 yoyo 自托管编译器可执行文件，不是 JavaScript。**

## 用法

```bash
npm run yoyo:build
# 等价于：yoyo/compiler/yoyo.exe yoyo/ternary_signal.ty build/ternary_signal.exe
```

在 Windows 上直接运行；在 Linux / macOS 上需通过 Wine 执行 `yoyo.exe`。

## 来源

从 yoyo-ide 仓库 `build/yoyo.exe` 原样获取，未经修改。
