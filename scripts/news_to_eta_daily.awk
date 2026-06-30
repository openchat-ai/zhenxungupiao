#!/usr/bin/awk -f
# 新闻标题关键词 → 日级 η 扰动分（0–100，50=中性）
# 输入：news_all.csv（无引号逗号冲突时可用）

BEGIN {
    FS = ","
    nb = split("涨,涨停,利好,回购,增持,分红,突破,创新高,盈利,超预期,反弹,大涨", bull, ",")
    nr = split("跌,跌停,利空,减持,亏损,调查,处罚,暴跌,下滑,违约,退市,大跌", bear, ",")
}

function count_kw(text,    i, c) {
    c = 0
    for (i = 1; i <= nb; i++)
        if (index(text, bull[i]) > 0) c++
    for (i = 1; i <= nr; i++)
        if (index(text, bear[i]) > 0) c -= 1
    return c
}

NR == 1 { next }
length($1) >= 10 && length($2) == 6 {
    key = $1 SUBSEP $2
    n_head[key]++
    score_delta[key] += count_kw($0)
}

END {
    print "date,code,news_score,n_headlines,bull_hits,bear_hits"
    for (k in n_head) {
        split(k, p, SUBSEP)
        raw = score_delta[k] + 0
        sc = 50 + raw * 8
        if (sc < 0) sc = 0
        if (sc > 100) sc = 100
        printf "%s,%s,%d,%d,%d,%d\n", p[1], p[2], sc, n_head[k], raw > 0 ? raw : 0, raw < 0 ? -raw : 0
    }
}
