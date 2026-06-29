# 震巽股票 — 纯 yoyo 零依赖构建

YOBO      := yoyo/compiler/yoyo.exe
YOBO_NEXT := build/yoyo_next.exe
BUILD     := build
MERGE     := $(BUILD)/yoyo_merged.ty

RUN = if command -v wine >/dev/null 2>&1; then wine $(1) $(2) $(3); else $(1) $(2) $(3); fi

.PHONY: all merge bootstrap compiler stock stock-gui stock-gui-elf signal clean

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
