LOVE := E:/Love2D/LOVE/love.exe
BUILD_DIR := build
RAW_LUA := lua
LUA_VER := 5.1
CYAN := cyan
LOGS := logs
BUSTED := busted
LUA_PATH := $(shell luarocks --tree rocks --lua-version=$(LUA_VER) path --full --lr-path)
LUA_CPATH := $(shell luarocks --tree rocks --lua-version=$(LUA_VER) path --full --lr-cpath)

.PHONY: all tests run clean

all:
	mkdir -p $(LOGS)
	@$(CYAN) build --prune
	@cp $(RAW_LUA)/** $(BUILD_DIR)/

# Busted config already calls `make all`
tests:
	@$(BUSTED) .

run:
	LUA_CPATH="$(LUA_CPATH)" LUA_PATH="$(LUA_PATH)" $(LOVE) $(BUILD_DIR) | tee $(LOGS)/latest.log

clean:
	@rm -rf ./$(BUILD_DIR)/*
