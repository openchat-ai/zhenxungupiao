import { useCallback, useRef, type PointerEvent as ReactPointerEvent } from 'react';

const DURATION = 500; // 长按判定时长(ms)
const MOVE_TOLERANCE = 10; // 长按期间允许的最大移动(px)

/** 长按手势：长按股票代码即可收藏/取消收藏。 */
export function useLongPress(onLongPress: () => void) {
  const timer = useRef<number | null>(null);
  const origin = useRef<{ x: number; y: number } | null>(null);
  const fired = useRef(false);

  const clear = useCallback(() => {
    if (timer.current !== null) {
      window.clearTimeout(timer.current);
      timer.current = null;
    }
  }, []);

  const onPointerDown = useCallback(
    (e: ReactPointerEvent) => {
      origin.current = { x: e.clientX, y: e.clientY };
      fired.current = false;
      clear();
      timer.current = window.setTimeout(() => {
        fired.current = true;
        onLongPress();
      }, DURATION);
    },
    [clear, onLongPress],
  );

  const onPointerMove = useCallback(
    (e: ReactPointerEvent) => {
      if (!origin.current) return;
      const dx = e.clientX - origin.current.x;
      const dy = e.clientY - origin.current.y;
      if (Math.abs(dx) > MOVE_TOLERANCE || Math.abs(dy) > MOVE_TOLERANCE) clear();
    },
    [clear],
  );

  const onPointerUp = useCallback(
    (e: ReactPointerEvent) => {
      clear();
      // 长按已触发：阻止冒泡，避免被当作普通点击/滑动
      if (fired.current) {
        e.stopPropagation();
      }
    },
    [clear],
  );

  const onPointerLeave = useCallback(() => clear(), [clear]);

  return { onPointerDown, onPointerMove, onPointerUp, onPointerLeave };
}
