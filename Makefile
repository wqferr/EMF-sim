LOVE := E:/Love2D/LOVE/love.exe
BUILD_DIR := build
RAW_LUA := lua
LUA_VER := 5.1
CYAN := cyan
BUSTED := busted
LUA_PATH := $(shell cygpath "$(shell luarocks --local --lua-version=$(LUA_VER) path --full --lr-path)")
LUA_CPATH := $(shell cygpath "$(shell luarocks --local --lua-version=$(LUA_VER) path --full --lr-cpath)")

.PHONY: all tests run clean

all:
	@$(CYAN) build --prune
	@cp $(RAW_LUA)/** $(BUILD_DIR)/

# Busted config already calls `make all`
tests:
	@$(BUSTED) .

run:
	@LUA_CPATH="$(LUA_CPATH)" LUA_PATH="$(LUA_PATH)" $(LOVE) $(BUILD_DIR)

clean:
	@rm -rf ./$(BUILD_DIR)/*
