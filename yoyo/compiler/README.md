# yoyo.exe — 官方三进制自托管编译器

来源：[openchat-ai/yoyo-ide](https://github.com/openchat-ai/yoyo-ide) `projects/yoyo.ty` + `build/yoyo.exe`

- **yoyo.ty**：与 upstream **同步**（2033 行，含 `0x82` JL / `0x83` JG + `H_9C` generic jcc）
- **yoyo.exe**：upstream 最新 PE（87040 B）
- **震巽扩展**：`patches/` Phase 2–4（float / ELF / GUI）经 `merge_compiler.sh` 合并

```bash
# Windows 本机
yoyo.exe input.ty output.exe

# Linux：优先 build/tyrun（原生 ELF）
./scripts/compile.sh flow_signal
```

应用层跳转请用 **`82` JL / `83` JG**（见 yoyo-ide `docs/MANUAL.md`），**勿用 `73`/`76`**（编译器内部编号）。
