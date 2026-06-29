# 震巽股票 — 纯 yoyo 构建（零外部依赖）

YOBO := yoyo/compiler/yoyo.exe
BUILD := build
STOCK_TY := $(BUILD)/stock_app.ty
SIGNAL_TY := yoyo/ternary_signal.ty

.PHONY: all signal stock clean

all: stock signal

stock: $(BUILD)/stock_app.exe

signal: $(BUILD)/ternary_signal.exe

$(STOCK_TY): yoyo/lib/fp.ty yoyo/lib/indicators.ty yoyo/ternary_signal.ty yoyo/stock_app.ty
	@mkdir -p $(BUILD)
	cat yoyo/lib/fp.ty yoyo/lib/indicators.ty yoyo/ternary_signal.ty yoyo/stock_app.ty > $@

$(BUILD)/stock_app.exe: $(STOCK_TY) $(YOBO)
	@mkdir -p $(BUILD)
	@if command -v wine >/dev/null 2>&1; then \
		wine $(YOBO) $(STOCK_TY) $@; \
	else \
		$(YOBO) $(STOCK_TY) $@; \
	fi
	@echo "Built $@"

$(BUILD)/ternary_signal.exe: $(SIGNAL_TY) $(YOBO)
	@mkdir -p $(BUILD)
	@if command -v wine >/dev/null 2>&1; then \
		wine $(YOBO) $(SIGNAL_TY) $@; \
	else \
		$(YOBO) $(SIGNAL_TY) $@; \
	fi
	@echo "Built $@"

clean:
	rm -rf $(BUILD)
