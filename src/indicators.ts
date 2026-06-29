import type { Candle } from './types';

/** 简单移动平均线 SMA。返回与输入等长的数组，未定义处为 NaN。 */
export function sma(values: number[], period: number): number[] {
  const out = new Array<number>(values.length).fill(NaN);
  let sum = 0;
  for (let i = 0; i < values.length; i++) {
    sum += values[i];
    if (i >= period) sum -= values[i - period];
    if (i >= period - 1) out[i] = sum / period;
  }
  return out;
}

/** 指数移动平均线 EMA。 */
export function ema(values: number[], period: number): number[] {
  const out = new Array<number>(values.length).fill(NaN);
  const k = 2 / (period + 1);
  let prev = NaN;
  for (let i = 0; i < values.length; i++) {
    const v = values[i];
    prev = Number.isNaN(prev) ? v : v * k + prev * (1 - k);
    out[i] = prev;
  }
  return out;
}

/** 相对强弱指标 RSI。 */
export function rsi(values: number[], period = 14): number[] {
  const out = new Array<number>(values.length).fill(NaN);
  let avgGain = 0;
  let avgLoss = 0;
  for (let i = 1; i < values.length; i++) {
    const change = values[i] - values[i - 1];
    const gain = Math.max(change, 0);
    const loss = Math.max(-change, 0);
    if (i <= period) {
      avgGain += gain;
      avgLoss += loss;
      if (i === period) {
        avgGain /= period;
        avgLoss /= period;
        out[i] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
      }
    } else {
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
      out[i] = avgLoss === 0 ? 100 : 100 - 100 / (1 + avgGain / avgLoss);
    }
  }
  return out;
}

export interface Macd {
  macd: number[];
  signal: number[];
  hist: number[];
}

/** MACD 指标（12, 26, 9）。 */
export function macd(values: number[], fast = 12, slow = 26, sig = 9): Macd {
  const emaFast = ema(values, fast);
  const emaSlow = ema(values, slow);
  const macdLine = values.map((_, i) => emaFast[i] - emaSlow[i]);
  const signal = ema(macdLine, sig);
  const hist = macdLine.map((v, i) => v - signal[i]);
  return { macd: macdLine, signal, hist };
}

export const closes = (candles: Candle[]): number[] => candles.map((c) => c.close);
