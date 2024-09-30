default: debug

BIN := hl
OUT_DIR := zig-out/bin

OPTIMIZE ?= Debug

run:
	zig build run

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

.PHONY: default run debug release install clean
