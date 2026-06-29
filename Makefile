# 震巽股票 — 纯 yoyo 零依赖构建

YOBO      := yoyo/compiler/yoyo.exe
YOBO_NEXT := build/yoyo_next.exe
BUILD     := build
MERGE     := $(BUILD)/yoyo_merged.ty

RUN = if command -v wine >/dev/null 2>&1; then wine $(1) $(2) $(3); else $(1) $(2) $(3); fi

.PHONY: all merge bootstrap compiler stock stock-gui stock-gui-elf signal clean \
  research-walk research-verify research-v2 research-v3 research-v4 \
  research-verify-v2 research-verify-v3 \
  butterfly-demo hold-ratio psychology-demo \
  fetch-news news-embed news-demo \
  fetch-ticks fetch-ticks-tdx tick-embed tick-demo

all: stock stock-gui

# ── 编译器自举（Phase 2/3/4 补丁）──
merge:
	@chmod +x scripts/merge_compiler.sh
	@./scripts/merge_compiler.sh

bootstrap: merge
	@mkdir -p $(BUILD)
	@$(call RUN,$(YOBO),$(MERGE),$(YOBO_NEXT))
	@echo "Bootstrapped $(YOBO_NEXT)"

compiler: bootstrap

# ── App 目标 ──
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

research-v2:
	@chmod +x scripts/backtest_v2.sh
	@./scripts/backtest_v2.sh

research-v3:
	@chmod +x scripts/backtest_v3.sh
	@./scripts/backtest_v3.sh

research-v4:
	@chmod +x scripts/backtest_v4.sh
	@./scripts/backtest_v4.sh

research-verify-v2:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-v2

research-verify-v3:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh verify-v3

psychology-demo:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh psychology

fetch-news:
	@chmod +x scripts/fetch_news_all.sh scripts/export_news_optional.py
	@./scripts/fetch_news_all.sh

extend-hist:
	@chmod +x scripts/extend_hist_all.sh scripts/export_hist_extend_optional.py
	@./scripts/extend_hist_all.sh

news-embed:
	@chmod +x scripts/news_to_embed.sh
	@mkdir -p build
	@./scripts/news_to_embed.sh research/archive/news_daily_eta.csv build/news_embed.ty $(or $(CODE),600519)

news-demo: news-embed
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh news

fetch-ticks:
	@chmod +x scripts/fetch_ticks_all.sh scripts/fetch_tick_eastmoney.sh
	@./scripts/fetch_ticks_all.sh

fetch-ticks-tdx:
	@chmod +x scripts/fetch_ticks_tdx_all.sh scripts/fetch_tick_tdx_optional.py
	@./scripts/fetch_ticks_tdx_all.sh $(or $(DAYS),10)

tick-embed:
	@chmod +x scripts/tick_to_embed.sh
	@mkdir -p build
	@./scripts/tick_to_embed.sh research/archive/tick_daily_summary.csv build/tick_embed.ty $(or $(CODE),600519)

tick-demo: tick-embed
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh tick

butterfly-demo:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh butterfly

hold-ratio:
	@chmod +x scripts/build_research.sh
	@./scripts/build_research.sh hold
