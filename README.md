# 震巽股票 — 手机 App

yoyo 平衡三进制极简选股 **手机 App**（Android / iOS），核心决策由 `yoyo.exe` 编译的 `ternary_signal.ty` 定义。

## 功能

- 上下滑切换股票，左滑全部 / 右滑收藏
- 长按股票代码收藏
- K 线 + 下方 **MACD / RSI** 指标子图
- 指标买卖信号：**紫色买入**、**绿色卖出**
- 四指标信号条（均线 / 趋势 / RSI / MACD）+ 综合三进制信号

## 架构

| 层 | 技术 | 说明 |
|---|---|---|
| 手机壳 | **Capacitor 8** | 打包为可安装的 Android / iOS App |
| 界面 | React + TypeScript + Canvas | K 线、指标、手势 |
| 决策核心 | **yoyo** (`ternary_signal.ty`) | 由官方 `yoyo.exe` 编译，与 `src/ternary.ts` 等价 |

> 界面层必须用可在手机上运行的技术；yoyo Phase-1 只有整数逻辑、无 GUI，因此指标计算在 TS，投票决策逻辑与 yoyo 源码一一对应。

## 开发

```bash
npm install
npm run dev          # 浏览器预览（手机尺寸）
```

## 打包手机 App

### 前置条件

- **Android**：Android Studio + JDK 17+，配置 `ANDROID_HOME`
- **iOS**：macOS + Xcode（仅 macOS 可构建）

### 构建并同步到原生工程

```bash
npm run mobile:build    # vite build + cap sync
```

### Android APK

```bash
npm run mobile:android  # 打开 Android Studio
# 在 Android Studio 中 Build → Build Bundle(s) / APK(s) → Build APK(s)
```

或直接命令行（需已配置 SDK）：

```bash
npm run mobile:run:android
```

### iOS

```bash
npm run mobile:ios      # 打开 Xcode，需 macOS
```

## yoyo 决策核心编译

```bash
npm run yoyo:build
# yoyo/compiler/yoyo.exe yoyo/ternary_signal.ty build/ternary_signal.exe
```

Windows 直接运行 `yoyo.exe`；Linux/macOS 需 Wine。

## 目录

```
src/                  React 手机界面
  components/         KLineChart（含指标子图）、StockCard、SignalBadge
  ternary.ts          三进制决策（与 yoyo 源码等价）
yoyo/
  ternary_signal.ty   yoyo 决策源码
  compiler/yoyo.exe   官方三进制编译器
android/              Capacitor Android 工程
ios/                  Capacitor iOS 工程
capacitor.config.ts   App 配置（包名 com.zhenxun.stock）
```
