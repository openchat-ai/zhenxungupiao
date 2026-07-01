# 用 yoyo.exe 直接编译（不用 make）

## 一句话

| 平台 | 编译器 | 命令 |
|------|--------|------|
| **Windows** | `yoyo/compiler/yoyo.exe` | `yoyo.exe build\flow_signal_demo.ty build\flow_signal_demo.exe` |
| **Linux** | `build/tyrun`（原生） | `./scripts/compile.sh flow_signal` |

`make` 和 `compile.sh` 都是**合并 .ty + 调编译器**，不是必须。

### 跳转 opcode（与 yoyo-ide 同步）

| Opcode | 含义 |
|--------|------|
| `71` | JE |
| **`82`** | **JL**（`<`） |
| **`83`** | **JG**（`>`） |

勿用 `73`/`76`（编译器内部编号）。详见 [yoyo-ide MANUAL](https://github.com/openchat-ai/yoyo-ide/blob/main/docs/MANUAL.md)。

---

## flow 买入/卖出指示（推荐）

```bash
# 1. 嵌入逐笔数据
./scripts/flow_to_embed.sh research/archive/tick_features_daily.csv build/flow_embed.ty 600036

# 2. 合并
cat yoyo/lib/fp.ty yoyo/lib/params.ty yoyo/lib/flow_signal.ty \
    build/flow_embed.ty yoyo/research/flow_signal_demo.ty \
  > build/flow_signal_demo.ty

# 3a. Windows 本机
yoyo/compiler/yoyo.exe build/flow_signal_demo.ty build/flow_signal_demo.exe
build/flow_signal_demo.exe

# 3b. Linux（tyrun 原生 ELF）
gcc -O2 -o build/tyrun yoyo/compiler/tyrun.c    # 首次
./build/tyrun -o build/flow_signal_demo build/flow_signal_demo.ty
./build/flow_signal_demo
# → signal=1 (0卖 1持 2买)
```

或一条：

```bash
./scripts/compile.sh flow_signal
./build/flow_signal_demo          # Linux ELF
# build/flow_signal_demo.exe      # Windows PE
```

---

## 为何 Linux 不用 yoyo.exe？

`yoyo.exe` 是**无 CRT 的 Windows PE**，在 Linux 上即使用 Wine 也会崩溃（`c0000005`）。  
因此 Linux 用同仓库的 **`yoyo/compiler/tyrun.c`**：读同一套 `.ty` 字节码，输出**原生 ELF**。

Windows 上仍优先 `yoyo.exe`（真 PE，零依赖）。

---

## 七票决策核心

```bash
./scripts/compile.sh signal
# Windows: yoyo.exe build/ternary_signal.ty build/ternary_signal.exe
# Linux:   build/ternary_signal（ELF）
```

---

## 合并规则

lib 顺序见 `scripts/compile.sh`。编译器只认**合并后的单个 `.ty` 文件**。
