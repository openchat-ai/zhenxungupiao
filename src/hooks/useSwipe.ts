import { useRef, type PointerEvent as ReactPointerEvent } from 'react';

interface SwipeHandlers {
  onSwipeUp?: () => void;
  onSwipeDown?: () => void;
  onSwipeLeft?: () => void;
  onSwipeRight?: () => void;
}

const THRESHOLD = 40; // 触发滑动所需的最小位移(px)

/**
 * 四方向滑动手势。基于 Pointer Events，鼠标拖拽与触摸都适用，
 * 方便在桌面浏览器里演示。
 */
export function useSwipe(handlers: SwipeHandlers) {
  const start = useRef<{ x: number; y: number } | null>(null);

  const onPointerDown = (e: ReactPointerEvent) => {
    start.current = { x: e.clientX, y: e.clientY };
  };

  const onPointerUp = (e: ReactPointerEvent) => {
    if (!start.current) return;
    const dx = e.clientX - start.current.x;
    const dy = e.clientY - start.current.y;
    start.current = null;

    if (Math.abs(dx) < THRESHOLD && Math.abs(dy) < THRESHOLD) return;

    if (Math.abs(dx) > Math.abs(dy)) {
      if (dx < 0) handlers.onSwipeLeft?.();
      else handlers.onSwipeRight?.();
    } else {
      if (dy < 0) handlers.onSwipeUp?.();
      else handlers.onSwipeDown?.();
    }
  };

  return { onPointerDown, onPointerUp };
}
