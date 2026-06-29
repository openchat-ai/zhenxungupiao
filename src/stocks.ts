import type { Candle, Stock } from './types';

/** 确定性伪随机数（mulberry32），保证每次刷新同一只股票走势一致。 */
function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function seedFromCode(code: string): number {
  let h = 2166136261;
  for (let i = 0; i < code.length; i++) {
    h ^= code.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/** 用几何随机游走 + 轻微趋势，生成一段看起来真实的日 K 线。 */
function genCandles(code: string, days = 120): Candle[] {
  const rng = mulberry32(seedFromCode(code));
  const candles: Candle[] = [];
  let price = 8 + rng() * 60; // 起始价 8 ~ 68 元
  // 给每只股票一个温和的长期趋势
  const drift = (rng() - 0.45) * 0.004;

  for (let i = 0; i < days; i++) {
    const open = price;
    const vol = 0.02 + rng() * 0.04; // 日波动率
    const change = (rng() - 0.5) * 2 * vol + drift;
    let close = open * (1 + change);
    if (close < 1) close = 1;
    const high = Math.max(open, close) * (1 + rng() * vol * 0.6);
    const low = Math.min(open, close) * (1 - rng() * vol * 0.6);
    const volume = Math.round((0.5 + rng()) * 1_000_000);
    candles.push({
      i,
      open: round2(open),
      high: round2(high),
      low: round2(low),
      close: round2(close),
      vol: volume,
    });
    price = close;
  }
  return candles;
}

const round2 = (x: number): number => Math.round(x * 100) / 100;

const UNIVERSE: Array<{ code: string; name: string }> = [
  { code: '600519', name: '贵州茅台' },
  { code: '000858', name: '五粮液' },
  { code: '601318', name: '中国平安' },
  { code: '600036', name: '招商银行' },
  { code: '000001', name: '平安银行' },
  { code: '300750', name: '宁德时代' },
  { code: '002594', name: '比亚迪' },
  { code: '600276', name: '恒瑞医药' },
  { code: '000333', name: '美的集团' },
  { code: '600900', name: '长江电力' },
  { code: '601012', name: '隆基绿能' },
  { code: '688981', name: '中芯国际' },
  { code: '600887', name: '伊利股份' },
  { code: '002415', name: '海康威视' },
  { code: '601899', name: '紫金矿业' },
];

/** 全市场股票（带行情数据）。 */
export const STOCKS: Stock[] = UNIVERSE.map((s) => ({
  ...s,
  candles: genCandles(s.code),
}));
