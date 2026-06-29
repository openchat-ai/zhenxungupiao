import { useCallback, useEffect, useState } from 'react';

const KEY = 'yoyo.favorites';

function load(): string[] {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.filter((x) => typeof x === 'string') : [];
  } catch {
    return [];
  }
}

/** 收藏功能：股票代码列表，持久化到 localStorage。 */
export function useFavorites() {
  const [favorites, setFavorites] = useState<string[]>(load);

  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(favorites));
    } catch {
      /* 忽略存储异常（如隐私模式） */
    }
  }, [favorites]);

  const isFavorite = useCallback(
    (code: string) => favorites.includes(code),
    [favorites],
  );

  const toggle = useCallback((code: string) => {
    setFavorites((prev) =>
      prev.includes(code) ? prev.filter((c) => c !== code) : [...prev, code],
    );
  }, []);

  return { favorites, isFavorite, toggle };
}
