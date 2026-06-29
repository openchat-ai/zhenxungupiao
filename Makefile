# 震巽股票 — 纯 yoyo 零依赖构建

YOBO      := yoyo/compiler/yoyo.exe
YOBO_NEXT := build/yoyo_next.exe
BUILD     := build
MERGE     := $(BUILD)/yoyo_merged.ty
CODES     := 000001 000333 000858 600036 600519 600900 601012 601318
CODE      ?= 600519

RUN = if command -v wine >/dev/null 2>&1; then wine $(1) $(2) $(3); else $(1) $(2) $(3); fi
RUNEXE = if command -v wine >/dev/null 2>&1; then wine $(1); else $(1); fi

.PHONY: all merge bootstrap compiler stock stock-gui stock-gui-elf signal clean \
  research-walk research-verify research-v2-yoyo research-v5-yoyo research-v5-tri-validate \
  research-verify-v2 research-verify-v3 verify-tri signal-today \
  butterfly-demo hold-ratio psychology-demo \
  fetch-news news-demo extend-hist \
  fetch-ticks fetch-ticks-tdx tick-demo

all: stock stock-gui

merge:
	@chmod +x scripts/merge_compiler.sh
	@./scripts/merge_compiler.sh

bootstrap: merge
	@mkdir -p $(BUILD)
	@$(call RUN,$(YOBO),$(MERGE),$(YOBO_NEXT))
	@echo "Bootstrapped $(YOBO_NEXT)"

compiler: bootstrap

stock:
	@chmod +x scripts/build.sh
	@./scripts/build.sh stock_app

stock-gui:
	@chmod +x scripts/build.sh
	@./scripts/build.sh stock_gui

stock-gui-elf: bootstrap
	@YOBO=$(YOBO_NEXT) chmod +x scripts/build.sh && \
	 YOBO=$(YOBO_NEXT) ./scripts/build.sh stock_gui_elf && \
	 mv $(BUILD)/stock_gui_elf.exe $(BUILD)/stock_gui_elf

signal:
	@mkdir -p $(BUILD)
	@$(call RUN,$(YOBO),yoyo/ternary_signal.ty,$(BUILD)/ternary_signal.exe)
	@echo "Built $(BUILD)/ternary_signal.exe"

clean:
	rm -rf $(BUILD)

research-walk:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh walk

research-verify:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify

# 纯 yoyo v2（signal_*.tri，无 CSV/awk）
research-v2-yoyo: verify-tri
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh backtest-v2
	@cp research/archive/signal_$(CODE).tri input.ky
	@$(call RUNEXE,$(BUILD)/backtest_v2.exe)

# 纯 yoyo v5 三版对照（flow_v5_*.tri）
research-v5-yoyo: verify-tri-v5
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh backtest-v5
	@cp research/archive/flow_v5_$(CODE).tri input.ky
	@$(call RUNEXE,$(BUILD)/backtest_v5_compare.exe)

# 校验八股 .tri 头 + 打印固化汇总（无 awk/python 回测）
research-v5-tri-validate: verify-tri-v5
	@echo "=== backtest_v5_tri_summary.json ==="
	@cat research/archive/backtest_v5_tri_summary.json

verify-tri:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-tri
	@for c in $(CODES); do \
	  test -f research/archive/signal_$$c.tri || (echo "missing signal_$$c.tri" && exit 1); \
	  cp research/archive/signal_$$c.tri input.ky; \
	  $(call RUNEXE,$(BUILD)/verify_tri.exe) || exit 1; \
	done
	@echo "OK signal_*.tri ×$(words $(CODES))"

verify-tri-v5:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-tri
	@for c in $(CODES); do \
	  test -f research/archive/flow_v5_$$c.tri || (echo "missing flow_v5_$$c.tri" && exit 1); \
	  cp research/archive/flow_v5_$$c.tri input.ky; \
	  $(call RUNEXE,$(BUILD)/verify_tri.exe) || exit 1; \
	done
	@echo "OK flow_v5_*.tri ×$(words $(CODES))"

# 八股最新 买/持/卖 一览（读 .tri 末日，给「今晚就想看见信号」用）
signal-today:
	@python3 scripts/signal_today.py

research-verify-v2:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-v2

research-verify-v3:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-v3

psychology-demo:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh psychology

# ── 以下 fetch 为可选数据刷新，不进 yoyo 回测主路径 ──
fetch-news:
	@chmod +x scripts/fetch_news_all.sh scripts/export_news_optional.py
	@./scripts/fetch_news_all.sh

extend-hist:
	@chmod +x scripts/extend_hist_all.sh scripts/export_hist_extend_optional.py
	@./scripts/extend_hist_all.sh

news-demo:
	@chmod +x scripts/build_research.sh
	@mkdir -p build
	@cp yoyo/research/embed/news_$(CODE).ty build/news_embed.ty 2>/dev/null || cp yoyo/research/embed/news_600519.ty build/news_embed.ty
	@./scripts/build_research.sh news

fetch-ticks:
	@chmod +x scripts/fetch_ticks_all.sh scripts/fetch_tick_eastmoney.sh
	@./scripts/fetch_ticks_all.sh

fetch-ticks-tdx:
	@chmod +x scripts/fetch_ticks_tdx_all.sh scripts/fetch_tick_tdx_optional.py scripts/prune_tick_hist.sh
	@./scripts/fetch_ticks_tdx_all.sh $(or $(YEAR),2026)

tick-demo:
	@chmod +x scripts/build_research.sh
	@mkdir -p build
	@cp yoyo/research/embed/tick_$(CODE).ty build/tick_embed.ty 2>/dev/null || cp yoyo/research/embed/tick_600519.ty build/tick_embed.ty
	@./scripts/build_research.sh tick

butterfly-demo:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh butterfly

hold-ratio:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh hold
