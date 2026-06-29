import type { Candle, SignalPoint, Trit } from './types';
import { closes, macd, rsi, sma } from './indicators';

/**
 * yoyo 平衡三进制选股引擎。
 *
 * 设计理念：「集百家之长，但极简」。
 * 我们把多个经典技术指标各自压缩成一个 trit（-1 / 0 / +1），
 * 然后用平衡三进制求和取符号（sgn）做多数表决，得到唯一的总信号：
 *
 *   ∑ tritᵢ  > 0  →  +1  买入
 *   ∑ tritᵢ  = 0  →   0  持有
 *   ∑ tritᵢ  < 0  →  -1  卖出
 *
 * 这正是平衡三进制最优雅的地方：一个 trit 同时编码了方向与强度，
 * 求和后的符号天然就是最终决策，无需任何 if/else 阈值堆叠。
 */

/** 平衡三进制取符号：把任意实数压成一个 trit。 */
export function trit(x: number): Trit {
  if (x > 0) return 1;
  if (x < 0) return -1;
  return 0;
}

const TRIT_LABEL: Record<Trit, string> = {
  [-1]: '卖出',
  [0]: '持有',
  [1]: '买入',
};

export const tritLabel = (t: Trit): string => TRIT_LABEL[t];

/** 单只股票每一根 K 线的总信号序列。 */
export function computeSignals(candles: Candle[]): SignalPoint[] {
  const price = closes(candles);
  const maFast = sma(price, 5);
  const maSlow = sma(price, 20);
  const ma10 = sma(price, 10);
  const r = rsi(price, 14);
  const m = macd(price);

  return candles.map((_, i) => {
    // 每一位专家投出一个 trit
    const votes: Trit[] = [
      // 1. 均线金叉/死叉：短期均线相对长期均线
      trit((maFast[i] || 0) - (maSlow[i] || 0)),
      // 2. 趋势：收盘价相对 10 日均线
      trit(price[i] - (ma10[i] || price[i])),
      // 3. RSI 超买超卖（注意：超卖看多 +1，超买看空 -1）
      Number.isNaN(r[i]) ? 0 : r[i] < 35 ? 1 : r[i] > 65 ? -1 : 0,
      // 4. MACD 柱状图方向
      Number.isNaN(m.hist[i]) ? 0 : trit(m.hist[i]),
    ];

    const sum = votes.reduce<number>((acc, v) => acc + v, 0);
    return { index: i, trit: trit(sum) };
  });
}

/** 当前（最后一根 K 线）的总信号。 */
export function currentTrit(signals: SignalPoint[]): Trit {
  return signals.length ? signals[signals.length - 1].trit : 0;
}

/** 找到最近一次「买入」翻转点的 K 线序号（信号由非 +1 变为 +1）。 */
export function lastBuyIndex(signals: SignalPoint[]): number | null {
  for (let i = signals.length - 1; i >= 1; i--) {
    if (signals[i].trit === 1 && signals[i - 1].trit !== 1) return signals[i].index;
  }
  return null;
}

/** 找到最近一次「卖出」翻转点的 K 线序号（信号由非 -1 变为 -1）。 */
export function lastSellIndex(signals: SignalPoint[]): number | null {
  for (let i = signals.length - 1; i >= 1; i--) {
    if (signals[i].trit === -1 && signals[i - 1].trit !== -1) return signals[i].index;
  }
  return null;
}
