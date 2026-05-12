LOVE := E:/Love2D/LOVE/love.exe
BUILD_DIR := build
CYAN = cyan

.PHONY: all run clean

all:
	$(CYAN) build

run:
	$(LOVE) $(BUILD_DIR)

clean:
	rm -r $(BUILD_DIR)/*
