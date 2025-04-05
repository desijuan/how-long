default: debug

BIN := hl
OUT_DIR := zig-out/bin

OPT_ENUM := Debug ReleaseSafe ReleaseFast ReleaseSmall
OPTIMIZE ?= Debug
ifeq ($(filter $(OPTIMIZE),$(OPT_ENUM)),)
$(error Invalid option: '$(OPTIMIZE)')
endif

$(OUT_DIR)/$(BIN):
	zig build -Doptimize=$(OPTIMIZE) --summary all

debug: OPTIMIZE := Debug
debug: $(OUT_DIR)/$(BIN)

release: OPTIMIZE := ReleaseSmall
release: $(OUT_DIR)/$(BIN)

install:
	cp $(OUT_DIR)/$(BIN) /usr/local/bin/

clean:
	rm -rf .zig-cache zig-out

.PHONY: default debug release install clean
