
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STAGE := $(MAKEFILE_DIR).build/src

game/codec:
	rm -rf "$(MAKEFILE_DIR)dist" "$(STAGE)"
	mkdir -p "$(STAGE)"
	cp "$(MAKEFILE_DIR)game.lua" "$(STAGE)/game.lua"
	cp -R "$(MAKEFILE_DIR)media/img" "$(STAGE)/img"
	cd "$(MAKEFILE_DIR)lupi-codec" && lua run.lua "$(STAGE)" "$(MAKEFILE_DIR)dist"

clean:
	rm -rf dist .build
