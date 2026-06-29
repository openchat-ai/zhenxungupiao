# yoyo.exe — 官方三进制自托管编译器

来源：[openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) `build/yoyo.exe`

- **不是 JavaScript**，是 PE32+ x86_64 原生可执行文件
- **零依赖**：无 CRT、无 Node、无第三方库
- 将 `.ty` 编译为 Windows 原生程序；多平台后端见 `docs/ROADMAP.md`

```bash
yoyo.exe input.ty output.exe
# 或：make stock
```

Linux/macOS 需 Wine 运行本二进制。
