import { useEffect, useRef } from 'react';
import type { Candle } from '../types';

interface Props {
  candles: Candle[];
  buyIndex: number | null;
  sellIndex: number | null;
}

// 中国 A 股习惯：涨为红，跌为绿
const UP = '#f6465d';
const DOWN = '#2ebd85';
const GRID = '#1b2129';
const AXIS = '#5b6673';

/** 极简 K 线图：纯 canvas 绘制，无第三方图表库。 */
export function KLineChart({ candles, buyIndex, sellIndex }: Props) {
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
    const padT = 14;
    const padB = 18;
    const plotW = cssW - padL - padR;
    const plotH = cssH - padT - padB;

    const hi = Math.max(...candles.map((c) => c.high));
    const lo = Math.min(...candles.map((c) => c.low));
    const range = hi - lo || 1;
    const y = (p: number) => padT + (1 - (p - lo) / range) * plotH;
    const n = candles.length;
    const slot = plotW / n;
    const bw = Math.max(1.5, slot * 0.62);

    // 背景网格 + 价格刻度
    ctx.font = '10px ui-monospace, monospace';
    ctx.textBaseline = 'middle';
    for (let g = 0; g <= 4; g++) {
      const gy = padT + (plotH * g) / 4;
      const price = lo + (range * (4 - g)) / 4;
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

    // K 线
    candles.forEach((c, i) => {
      const cx = padL + slot * i + slot / 2;
      const up = c.close >= c.open;
      const color = up ? UP : DOWN;
      ctx.strokeStyle = color;
      ctx.fillStyle = color;
      ctx.lineWidth = 1;
      // 影线
      ctx.beginPath();
      ctx.moveTo(cx, y(c.high));
      ctx.lineTo(cx, y(c.low));
      ctx.stroke();
      // 实体
      const yo = y(c.open);
      const yc = y(c.close);
      const top = Math.min(yo, yc);
      const bodyH = Math.max(1, Math.abs(yc - yo));
      ctx.fillRect(cx - bw / 2, top, bw, bodyH);
    });

    // 买/卖信号标记
    const marker = (index: number | null, isBuy: boolean) => {
      if (index === null || index < 0 || index >= n) return;
      const c = candles[index];
      const cx = padL + slot * index + slot / 2;
      const color = isBuy ? UP : DOWN;
      const py = isBuy ? y(c.low) + 14 : y(c.high) - 14;
      const dir = isBuy ? -1 : 1; // 买在下方朝上，卖在上方朝下
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.moveTo(cx, py + dir * -7);
      ctx.lineTo(cx - 5, py + dir * 4);
      ctx.lineTo(cx + 5, py + dir * 4);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 9px ui-monospace, monospace';
      ctx.textAlign = 'center';
      ctx.fillText(isBuy ? 'B' : 'S', cx, py + dir * -1);
    };
    marker(buyIndex, true);
    marker(sellIndex, false);
  }, [candles, buyIndex, sellIndex]);

  return <canvas ref={canvasRef} className="kline-canvas" />;
}
