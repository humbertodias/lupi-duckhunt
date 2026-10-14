
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STAGE := $(MAKEFILE_DIR).build/src
LUPI := $(MAKEFILE_DIR)duckhunt.lupi

.PHONY: game/codec lupi clean

game/codec:
	rm -rf "$(MAKEFILE_DIR)dist" "$(STAGE)"
	mkdir -p "$(STAGE)"
	cp "$(MAKEFILE_DIR)game.lua" "$(STAGE)/game.lua"
	cp -R "$(MAKEFILE_DIR)media/img" "$(STAGE)/img"
	mkdir -p "$(STAGE)/sfx"
	cp "$(MAKEFILE_DIR)media/sfx/"*.ogg "$(STAGE)/sfx/"
	cd "$(MAKEFILE_DIR)lupi-codec" && lua run.lua "$(STAGE)" "$(MAKEFILE_DIR)dist"

lupi: game/codec
	rm -f "$(LUPI)"
	cd "$(MAKEFILE_DIR)dist/current" && zip -r -X "$(LUPI)" .
	@echo "Gerado: $(LUPI)"

clean:
	rm -rf dist .build "$(LUPI)"
