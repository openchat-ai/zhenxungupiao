import type { Trit } from '../types';
import { tritLabel } from '../ternary';

const STYLE: Record<Trit, { bg: string; fg: string; mark: string }> = {
  [1]: { bg: '#f6465d', fg: '#fff', mark: '+1' },
  [0]: { bg: '#39424e', fg: '#cfd6dd', mark: '0' },
  [-1]: { bg: '#2ebd85', fg: '#fff', mark: '-1' },
};

/** 把唯一的三进制信号渲染成醒目的横幅。 */
export function SignalBadge({ trit }: { trit: Trit }) {
  const s = STYLE[trit];
  return (
    <div className="signal-badge" style={{ background: s.bg, color: s.fg }}>
      <span className="signal-label">{tritLabel(trit)}</span>
      <span className="signal-trit">trit {s.mark}</span>
    </div>
  );
}
