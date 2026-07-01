#!/usr/bin/awk -f
# 震巽股票 M2 — 横截面 rank-IC / ICIR 引擎（纯 awk，universe-size-agnostic）
# 输入：拼好的面板 date,code,mom,rev,vol,turn,fwd （见 panel_features.awk）
# 每个「调仓日」跨股票排序，算 Spearman rank-IC(factor, fwd) + 多空价差。
# 前瞻窗按 h 天非重叠采样 → IC 序列近似独立（这就是防重叠/purging 的采样机制）。
#
# 参数：-v rebfile=<调仓日列表> -v split_date= -v h= -v factors="mom,rev,vol,turn"
#        -v c_buy= -v c_sell=  （多头满仓轮动的保守成本）
# 输出：factor,segment,n_periods,mean_ic,ic_t,icir,ls_ann_gross,ls_t,lo_ann_net,avg_breadth
BEGIN {
    FS = ","
    if (h == "") h = 5
    if (split_date == "") split_date = "2024-01-01"
    if (factors == "") factors = "mom,rev,vol,turn"
    if (c_buy == "") c_buy = 0.00075
    if (c_sell == "") c_sell = 0.00125
    nf = split(factors, farr, ",")
    fcol["mom"]=3; fcol["rev"]=4; fcol["vol"]=5; fcol["turn"]=6
    while ((getline line < rebfile) > 0) { gsub(/[ \t\r]/,"",line); if(line!="") reb[line]=1 }
    close(rebfile)
    ppy = 252.0 / h        # 每年调仓次数（年化用）
}
$1 in reb {
    d = $1; cnt[d]++; k = cnt[d]
    V[d,k,3]=$3+0; V[d,k,4]=$4+0; V[d,k,5]=$5+0; V[d,k,6]=$6+0
    Yv[d,k]=$7+0
    seen[d]=1
}
function pearson(rx, ry, m,    j, sx, sy, sxx, syy, sxy, den) {
    sx=sy=sxx=syy=sxy=0
    for (j=1;j<=m;j++){ sx+=rx[j]; sy+=ry[j]; sxx+=rx[j]*rx[j]; syy+=ry[j]*ry[j]; sxy+=rx[j]*ry[j] }
    den = sqrt((m*sxx-sx*sx)*(m*syy-sy*sy))
    return (den>0)? (m*sxy-sx*sy)/den : 0
}
END {
    for (d in seen) {
        m = cnt[d]
        if (m < 4) continue                         # 太少不算横截面
        seg = (d < split_date) ? "is" : "oos"
        median = (m+1)/2.0
        for (fi=1; fi<=nf; fi++) {
            f = farr[fi]; col = fcol[f]
            # 收集横截面
            for (k=1;k<=m;k++){ xv[k]=V[d,k,col]; yv[k]=Yv[d,k] }
            # 平均秩（含并列）
            for (k=1;k<=m;k++){
                lx=ex=ly=ey=0
                for (j=1;j<=m;j++){
                    if (xv[j]<xv[k]) lx++; else if (xv[j]==xv[k]) ex++
                    if (yv[j]<yv[k]) ly++; else if (yv[j]==yv[k]) ey++
                }
                rx[k]=lx+1+(ex-1)/2.0
                ry[k]=ly+1+(ey-1)/2.0
            }
            ic = pearson(rx, ry, m)
            ICn[f,seg]++; ICs[f,seg]+=ic; ICss[f,seg]+=ic*ic; BRD[f,seg]+=m
            # 多空 / 多头 价差（按因子秩上/下半）
            sumL=cntL=sumS=cntS=sumAll=0
            for (k=1;k<=m;k++){
                sumAll+=yv[k]
                if (rx[k]>median){ sumL+=yv[k]; cntL++ }
                else if (rx[k]<median){ sumS+=yv[k]; cntS++ }
            }
            if (cntL>0 && cntS>0){
                ls = sumL/cntL - sumS/cntS
                LSn[f,seg]++; LSs[f,seg]+=ls; LSss[f,seg]+=ls*ls
                lo = sumL/cntL - sumAll/m
                lonet = lo - (c_buy + c_sell)        # 保守：每次调仓多头全额轮动
                LOn[f,seg]++; LOs[f,seg]+=lonet
            }
        }
    }
    for (fi=1; fi<=nf; fi++){
        f = farr[fi]
        for (segi=1; segi<=2; segi++){
            seg = (segi==1)?"is":"oos"
            n = ICn[f,seg]; if (n<2) continue
            mic = ICs[f,seg]/n
            var = (ICss[f,seg]-n*mic*mic)/(n-1); sd = (var>0)?sqrt(var):0
            ic_t = (sd>0)? mic/(sd/sqrt(n)) : 0
            icir = (sd>0)? mic/sd*sqrt(ppy) : 0
            brd = BRD[f,seg]/n
            # LS 年化 + t
            ln = LSn[f,seg]; lm = (ln>0)?LSs[f,seg]/ln:0
            lvar = (ln>1)?(LSss[f,seg]-ln*lm*lm)/(ln-1):0; lsd=(lvar>0)?sqrt(lvar):0
            ls_t = (lsd>0)? lm/(lsd/sqrt(ln)) : 0
            ls_ann = lm*ppy
            lonet_ann = (LOn[f,seg]>0)? LOs[f,seg]/LOn[f,seg]*ppy : 0
            printf("%s,%s,%d,%.5f,%.3f,%.3f,%.5f,%.3f,%.5f,%.2f\n",
                   f, seg, n, mic, ic_t, icir, ls_ann, ls_t, lonet_ann, brd)
        }
    }
}
