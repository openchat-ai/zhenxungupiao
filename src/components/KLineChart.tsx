import { useEffect, useRef } from 'react';
import type { Macd } from '../indicators';
import type { Candle, IndicatorName, IndicatorVotePoint } from '../types';
import { INDICATOR_NAMES } from '../types';

interface Props {
  candles: Candle[];
  buyIndex: number | null;
  sellIndex: number | null;
  votes: IndicatorVotePoint[];
  macd: Macd;
  rsiValues: number[];
}

// 中国 A 股习惯：涨为红，跌为绿
const UP = '#f6465d';
const DOWN = '#2ebd85';
// 指标买卖信号：紫买 / 绿卖
const SIGNAL_BUY = '#a855f7';
const SIGNAL_SELL = '#2ebd85';
const GRID = '#1b2129';
const AXIS = '#5b6673';
const LABEL = '#7a8794';

function xPos(padL: number, slot: number, i: number) {
  return padL + slot * i + slot / 2;
}

/** 在指标子图上绘制紫色买入 / 绿色卖出圆点。 */
function drawSignalDots(
  ctx: CanvasRenderingContext2D,
  padL: number,
  slot: number,
  n: number,
  yAt: (i: number, vote: 1 | -1) => number,
  getVote: (i: number) => 1 | -1 | 0,
) {
  for (let i = 0; i < n; i++) {
    const vote = getVote(i);
    if (vote === 0) continue;
    const color = vote === 1 ? SIGNAL_BUY : SIGNAL_SELL;
    const cx = xPos(padL, slot, i);
    const cy = yAt(i, vote);
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(cx, cy, Math.max(2.2, slot * 0.18), 0, Math.PI * 2);
    ctx.fill();
  }
}

/** K 线 + 下方 MACD / RSI 指标子图，指标上出现紫买 / 绿卖信号。 */
export function KLineChart({
  candles,
  buyIndex,
  sellIndex,
  votes,
  macd,
  rsiValues,
}: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const parent = canvas.parentElement;
    if (!parent) return;

    const dpr = window.devicePixelRatio || 1;
    const cssW = parent.clientWidth;
    const cssH = parent.clientHeight;
    canvas.width = Math.floor(cssW * dpr);
    canvas.height = Math.floor(cssH * dpr);
    canvas.style.width = `${cssW}px`;
    canvas.style.height = `${cssH}px`;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, cssW, cssH);

    if (candles.length === 0) return;

    const padL = 6;
    const padR = 52;
    const padT = 10;
    const padB = 6;
    const plotW = cssW - padL - padR;
    const n = candles.length;
    const slot = plotW / n;

    // 纵向分区：K 线 48% · MACD 24% · RSI 18% · 四指标信号条 10%
    const gap = 6;
    const stripH = Math.max(28, cssH * 0.1);
    const rsiH = Math.max(52, cssH * 0.18);
    const macdH = Math.max(52, cssH * 0.24);
    const kH = cssH - padT - padB - stripH - rsiH - macdH - gap * 3;
    const kTop = padT;
    const macdTop = kTop + kH + gap;
    const rsiTop = macdTop + macdH + gap;
    const stripTop = rsiTop + rsiH + gap;

    const hi = Math.max(...candles.map((c) => c.high));
    const lo = Math.min(...candles.map((c) => c.low));
    const range = hi - lo || 1;
    const yK = (p: number) => kTop + (1 - (p - lo) / range) * kH;
    const bw = Math.max(1.5, slot * 0.62);

    const drawHGrid = (top: number, h: number, loVal: number, hiVal: number) => {
      const r = hiVal - loVal || 1;
      const y = (v: number) => top + (1 - (v - loVal) / r) * h;
      ctx.font = '9px ui-monospace, monospace';
      ctx.textBaseline = 'middle';
      for (let g = 0; g <= 2; g++) {
        const gy = top + (h * g) / 2;
        const price = loVal + (r * (2 - g)) / 2;
        ctx.strokeStyle = GRID;
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(padL, gy);
        ctx.lineTo(padL + plotW, gy);
        ctx.stroke();
        ctx.fillStyle = AXIS;
        ctx.textAlign = 'left';
        ctx.fillText(price.toFixed(2), padL + plotW + 4, gy);
      }
      return y;
    };

    // ── K 线主图 ──
    drawHGrid(kTop, kH, lo, hi);
    candles.forEach((c, i) => {
      const cx = xPos(padL, slot, i);
      const up = c.close >= c.open;
      const color = up ? UP : DOWN;
      ctx.strokeStyle = color;
      ctx.fillStyle = color;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(cx, yK(c.high));
      ctx.lineTo(cx, yK(c.low));
      ctx.stroke();
      const yo = yK(c.open);
      const yc = yK(c.close);
      const top = Math.min(yo, yc);
      const bodyH = Math.max(1, Math.abs(yc - yo));
      ctx.fillRect(cx - bw / 2, top, bw, bodyH);
    });

    const marker = (index: number | null, isBuy: boolean) => {
      if (index === null || index < 0 || index >= n) return;
      const c = candles[index];
      const cx = xPos(padL, slot, index);
      const color = isBuy ? SIGNAL_BUY : SIGNAL_SELL;
      const py = isBuy ? yK(c.low) + 12 : yK(c.high) - 12;
      const dir = isBuy ? -1 : 1;
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.moveTo(cx, py + dir * -6);
      ctx.lineTo(cx - 4, py + dir * 3);
      ctx.lineTo(cx + 4, py + dir * 3);
      ctx.closePath();
      ctx.fill();
    };
    marker(buyIndex, true);
    marker(sellIndex, false);

    // ── MACD 子图 ──
    ctx.fillStyle = LABEL;
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('MACD', padL, macdTop - 2);
    const macdVals = macd.hist.filter((v) => !Number.isNaN(v));
    const macdLo = Math.min(0, ...macdVals, ...macd.macd.filter((v) => !Number.isNaN(v)));
    const macdHi = Math.max(0, ...macdVals, ...macd.macd.filter((v) => !Number.isNaN(v)));
    const yMacd = drawHGrid(macdTop, macdH, macdLo, macdHi);
    const zeroY = yMacd(0);
    ctx.strokeStyle = '#39424e';
    ctx.beginPath();
    ctx.moveTo(padL, zeroY);
    ctx.lineTo(padL + plotW, zeroY);
    ctx.stroke();
    candles.forEach((_, i) => {
      const h = macd.hist[i];
      if (Number.isNaN(h)) return;
      const cx = xPos(padL, slot, i);
      const color = h >= 0 ? UP : DOWN;
      const y0 = zeroY;
      const y1 = yMacd(h);
      ctx.strokeStyle = color;
      ctx.lineWidth = Math.max(1, slot * 0.5);
      ctx.beginPath();
      ctx.moveTo(cx, y0);
      ctx.lineTo(cx, y1);
      ctx.stroke();
    });
    drawSignalDots(ctx, padL, slot, n, (_i, vote) => (vote === 1 ? macdTop + macdH - 4 : macdTop + 4), (i) =>
      votes[i]?.votes.MACD ?? 0,
    );

    // ── RSI 子图 ──
    ctx.fillStyle = LABEL;
    ctx.fillText('RSI', padL, rsiTop - 2);
    const yRsi = drawHGrid(rsiTop, rsiH, 0, 100);
    [35, 65].forEach((lv) => {
      const ly = yRsi(lv);
      ctx.strokeStyle = '#39424e';
      ctx.setLineDash([3, 3]);
      ctx.beginPath();
      ctx.moveTo(padL, ly);
      ctx.lineTo(padL + plotW, ly);
      ctx.stroke();
      ctx.setLineDash([]);
    });
    ctx.strokeStyle = '#6b9fff';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    let started = false;
    for (let i = 0; i < n; i++) {
      const v = rsiValues[i];
      if (Number.isNaN(v)) continue;
      const cx = xPos(padL, slot, i);
      const cy = yRsi(v);
      if (!started) {
        ctx.moveTo(cx, cy);
        started = true;
      } else ctx.lineTo(cx, cy);
    }
    ctx.stroke();
    drawSignalDots(ctx, padL, slot, n, (_i, vote) => (vote === 1 ? rsiTop + rsiH - 4 : rsiTop + 4), (i) =>
      votes[i]?.votes.RSI ?? 0,
    );

    // ── 四指标信号条（均线 / 趋势 / RSI / MACD）──
    const rowH = stripH / INDICATOR_NAMES.length;
    INDICATOR_NAMES.forEach((name, row) => {
      const rowTop = stripTop + row * rowH;
      ctx.fillStyle = LABEL;
      ctx.font = '9px sans-serif';
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      ctx.fillText(name, padL, rowTop + rowH / 2);
      const barTop = rowTop + 2;
      const barH = rowH - 4;
      const barL = padL + 30;
      const barW = plotW - 30;
      const barSlot = barW / n;
      for (let i = 0; i < n; i++) {
        const vote = votes[i]?.votes[name as IndicatorName] ?? 0;
        if (vote === 0) continue;
        const color = vote === 1 ? SIGNAL_BUY : SIGNAL_SELL;
        ctx.fillStyle = color;
        const cx = barL + barSlot * i + barSlot / 2;
        ctx.fillRect(cx - barSlot * 0.3, barTop, barSlot * 0.6, barH);
      }
    });
  }, [candles, buyIndex, sellIndex, votes, macd, rsiValues]);

  return <canvas ref={canvasRef} className="kline-canvas" />;
}
