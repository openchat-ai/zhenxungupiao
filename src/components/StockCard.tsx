import { useMemo } from 'react';
import type { Stock } from '../types';
import {
  computeSignals,
  currentTrit,
  lastBuyIndex,
  lastSellIndex,
} from '../ternary';
import { KLineChart } from './KLineChart';
import { SignalBadge } from './SignalBadge';
import { useLongPress } from '../hooks/useLongPress';

interface Props {
  stock: Stock;
  isFavorite: boolean;
  onToggleFavorite: () => void;
}

/** 单只股票的整屏卡片：股票代码 + K 线 + 唯一买卖信号。 */
export function StockCard({ stock, isFavorite, onToggleFavorite }: Props) {
  const { signals, trit, buyIndex, sellIndex } = useMemo(() => {
    const s = computeSignals(stock.candles);
    return {
      signals: s,
      trit: currentTrit(s),
      buyIndex: lastBuyIndex(s),
      sellIndex: lastSellIndex(s),
    };
  }, [stock]);

  const last = stock.candles[stock.candles.length - 1];
  const prev = stock.candles[stock.candles.length - 2] ?? last;
  const chg = ((last.close - prev.close) / prev.close) * 100;
  const longPress = useLongPress(onToggleFavorite);

  return (
    <div className="card">
      <header className="card-head">
        <div className="code-block" {...longPress} title="长按收藏 / 取消收藏">
          <span className="name">{stock.name}</span>
          <span className="code">
            {stock.code}
            {isFavorite && <span className="star">★</span>}
          </span>
        </div>
        <div className="price-block">
          <span className="price" style={{ color: chg >= 0 ? '#f6465d' : '#2ebd85' }}>
            {last.close.toFixed(2)}
          </span>
          <span className="chg" style={{ color: chg >= 0 ? '#f6465d' : '#2ebd85' }}>
            {chg >= 0 ? '+' : ''}
            {chg.toFixed(2)}%
          </span>
        </div>
      </header>

      <div className="chart-wrap">
        <KLineChart candles={stock.candles} buyIndex={buyIndex} sellIndex={sellIndex} />
      </div>

      <SignalBadge trit={trit} />

      <div className="hint">
        长按代码收藏 · 上下滑翻股票 · 左滑全部 / 右滑收藏 · 共 {signals.length} 根 K 线
      </div>
    </div>
  );
}
