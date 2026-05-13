LOVE := E:/Love2D/LOVE/love.exe
BUILD_DIR := build
RAW_LUA := lua
CYAN := cyan
BUSTED := busted
LUA_PATH := "./build/?.lua;./build/?/?.lua;./build/?/init.lua"
BUSTED_FLAGS := --lpath=$(LUA_PATH) --defer-print

.PHONY: all run clean

all:
	@$(CYAN) build --prune
	@cp $(RAW_LUA)/** $(BUILD)/

tests: all
	@$(BUSTED) $(BUSTED_FLAGS) .

run:
	@$(LOVE) $(BUILD_DIR)

clean:
	@rm -r $(BUILD_DIR)/*
