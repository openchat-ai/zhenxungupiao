import { useCallback, useEffect, useMemo, useState } from 'react';
import { STOCKS } from './stocks';
import { useFavorites } from './hooks/useFavorites';
import { useSwipe } from './hooks/useSwipe';
import { StockCard } from './components/StockCard';

type Mode = 'all' | 'fav';

export default function App() {
  const { isFavorite, toggle, favorites } = useFavorites();
  const [mode, setMode] = useState<Mode>('all');
  const [allIdx, setAllIdx] = useState(0);
  const [favIdx, setFavIdx] = useState(0);
  const [toast, setToast] = useState<string | null>(null);

  const favStocks = useMemo(
    () => STOCKS.filter((s) => favorites.includes(s.code)),
    [favorites],
  );

  const list = mode === 'all' ? STOCKS : favStocks;
  const idx = mode === 'all' ? allIdx : favIdx;
  const setIdx = mode === 'all' ? setAllIdx : setFavIdx;
  const current = list[Math.min(idx, list.length - 1)];

  const flash = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 1300);
  }, []);

  const next = useCallback(() => {
    if (list.length === 0) return;
    setIdx((i) => (i + 1) % list.length);
  }, [list.length, setIdx]);

  const prev = useCallback(() => {
    if (list.length === 0) return;
    setIdx((i) => (i - 1 + list.length) % list.length);
  }, [list.length, setIdx]);

  const goAll = useCallback(() => {
    setMode('all');
    flash('全部股票');
  }, [flash]);

  const goFav = useCallback(() => {
    setMode('fav');
    flash('我的收藏');
  }, [flash]);

  const onToggleFavorite = useCallback(() => {
    if (!current) return;
    const willAdd = !isFavorite(current.code);
    toggle(current.code);
    flash(willAdd ? `已收藏 ${current.name}` : `已取消收藏 ${current.name}`);
  }, [current, isFavorite, toggle, flash]);

  const swipe = useSwipe({
    onSwipeUp: next,
    onSwipeDown: prev,
    onSwipeLeft: goAll,
    onSwipeRight: goFav,
  });

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowUp':
          e.preventDefault();
          next();
          break;
        case 'ArrowDown':
          e.preventDefault();
          prev();
          break;
        case 'ArrowLeft':
          goAll();
          break;
        case 'ArrowRight':
          goFav();
          break;
        case 'f':
        case 'F':
          onToggleFavorite();
          break;
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [next, prev, goAll, goFav, onToggleFavorite]);

  return (
    <div className="app" {...swipe}>
      <div className="topbar">
        <button
          className={mode === 'all' ? 'tab active' : 'tab'}
          onClick={goAll}
          type="button"
        >
          全部
        </button>
        <button
          className={mode === 'fav' ? 'tab active' : 'tab'}
          onClick={goFav}
          type="button"
        >
          收藏 {favStocks.length > 0 && <span className="count">{favStocks.length}</span>}
        </button>
        <div className="brand">震巽 · yoyo</div>
      </div>

      {current ? (
        <>
          <StockCard
            key={current.code}
            stock={current}
            isFavorite={isFavorite(current.code)}
            onToggleFavorite={onToggleFavorite}
          />
          <div className="pager">
            {idx + 1} / {list.length}
          </div>
        </>
      ) : (
        <div className="empty">
          <div className="empty-emoji">★</div>
          <p>还没有收藏的股票</p>
          <p className="empty-sub">在「全部」里长按股票代码即可收藏</p>
          <button className="empty-btn" onClick={goAll} type="button">
            去看全部股票
          </button>
        </div>
      )}

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
