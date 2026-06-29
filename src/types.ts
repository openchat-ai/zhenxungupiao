/**
 * yoyo 平衡三进制（balanced ternary）的基本单元：trit。
 * 取值只有三种，恰好对应交易里的三种动作：
 *   -1 → 卖出 (SELL)
 *    0 → 持有 (HOLD)
 *   +1 → 买入 (BUY)
 */
export type Trit = -1 | 0 | 1;

export interface Candle {
  /** 第几根 K 线（从 0 开始的序号） */
  i: number;
  open: number;
  high: number;
  low: number;
  close: number;
  vol: number;
}

export interface Stock {
  code: string;
  name: string;
  candles: Candle[];
}

/** 某一根 K 线上的三进制信号 */
export interface SignalPoint {
  index: number;
  trit: Trit;
}
