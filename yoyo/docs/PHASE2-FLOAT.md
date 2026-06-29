# yoyo Phase 2：浮点扩展规范

> yoyo 是**零依赖**万能编译器：`.ty` → 任意平台原生程序。
> 浮点能力在现有整数 opcode 基础上扩展，不引入任何外部库。

## 设计原则

1. **零依赖**：编译器自身由 `yoyo.exe` 自举，产物无 CRT / Node / 第三方库
2. **渐进扩展**：Phase 1 整数 → Phase 2 浮点 → Phase 3 多目标 → Phase 4 GUI
3. **状态槽即数据**：`state[N]` 存 IEEE754 `float64` 的位模式（64 位整数槽）
4. **软件实现优先**：新 opcode 是对 x86_64 SSE2 / ARM64 NEON 的薄封装，逻辑可在 `.ty` 中自举验证

## 新增 Opcode（0x90–0x9F）

| Opcode | 参数 | 含义 | x64 发射 |
|--------|------|------|----------|
| `90` | `dst, src` | FLOAD：`state[dst] = (double)state[src]` 整数→浮点位模式 | `cvtsi2sd` |
| `91` | `dst, a, b` | FADD：`state[dst] = fp(state[a]) + fp(state[b])` | `addsd` |
| `92` | `dst, a, b` | FSUB | `subsd` |
| `93` | `dst, a, b` | FMUL | `mulsd` |
| `94` | `dst, a, b` | FDIV | `divsd` |
| `95` | `a, b` | FCMP：比较，设置标志位供 `71`–`7A` 使用 | `comisd` |
| `96` | `dst, imm32` | FSET：写入 IEEE754 立即数（4 字节 hex 跟在后面） | `movsd` |
| `97` | `dst, src` | F2I：浮点截断为整数存入 `state[dst]` | `cvttsd2si` |
| `98` | `dst, src` | I2F：整数转为浮点位模式 | `cvtsi2sd` |
| `99` | `dst, a, b` | FMA：`dst = a*b + c`（可选，Phase 2b） | `fmaddsd` |

## 过渡方案：定点库 `lib/fp.ty`

在编译器尚未发射 `0x90`–`0x9F` 之前，用**定点整数**（价格 × 10000）实现指标运算。
`lib/fp.ty` 全部用 Phase 1/1.5 已有 opcode（`68` ADD、`69` SUB、`63` IMUL、循环除法）。

编译器合并进 `stock_app.ty` 后由 `yoyo.exe` 一次编译，无链接器、无外部库。

## 自举路径

```
1. 在 projects/yoyo.ty（编译器源码）中为 0x90–0x9F 添加 emitter handler
2. yoyo.exe projects/yoyo.ty → build/yoyo_new.exe
3. bootstrap-check：新旧编译器输出字节一致（或按基线更新）
4. 用新编译器编译 stock_app.ty，指标改用真浮点 opcode
```

## 多平台（Phase 3 预览）

| 目标 | 格式 | 状态 |
|------|------|------|
| Windows x64 | PE32+ | ✅ 当前 |
| Linux x64 | ELF64 | 待扩展 pe-builder → elf-builder |
| Android arm64 | ELF64 + JNI 薄壳 | 待扩展 |
| iOS arm64 | Mach-O | 待扩展 |

同一套 `.ty` 源码，换后端发射器即可——这是 yoyo 作为万能编译器的核心设计。
