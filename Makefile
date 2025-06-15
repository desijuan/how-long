.DEFAULT_GOAL := debug

BIN := hl

debug:
	zig build --summary all

release:
	zig build -Doptimize=ReleaseSmall --summary all

clean:
	rm -rf .zig-cache zig-out

install:
	cp zig-out/bin/$(BIN) /usr/local/bin/

uninstall:
	rm /usr/local/bin/$(BIN)

.PHONY: debug release clean install uninstall
