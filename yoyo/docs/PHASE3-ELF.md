# Phase 3：ELF64 多目标后端

## 编译期切换

在 `.ty` 源文件**首行**写入：

```
A2 00    ; PE32+ Windows（默认）
A2 01    ; ELF64 Linux / Android
```

编译器将 `state[99]` 设为输出格式。写入阶段 `H_EF` 把文件头替换为 ELF magic `7F 45 4C 46`。

## 目标平台

| state[99] | 格式 | 用途 |
|-----------|------|------|
| 0 | PE32+ | Windows x64 |
| 1 | ELF64 | Linux、Android（arm64 后端待扩展） |

## 构建

```bash
make bootstrap          # 合并补丁 → yoyo_merged.ty → yoyo_next.exe
make stock-gui          # PE 版 GUI App
make stock-gui-elf      # ELF 版（Linux/Android 第一步）
```

## Android 路径

1. `A2 01` 编译为 ELF64
2. Phase 3b：增加 `A2 02` = AArch64 ELF
3. Phase 3c：最小 Android Activity 加载 `.so`（仍由 yoyo 生成，无 Gradle 依赖）

## 零依赖

ELF 头由编译器内嵌 `H_EF` 写入，不链接 libc。`execve` 直接加载需完整 program header（后续迭代补齐 PT_LOAD 段）。
