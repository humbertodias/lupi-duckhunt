
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STAGE := $(MAKEFILE_DIR).build/src
CURRENT := $(MAKEFILE_DIR)dist/current
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
	mkdir -p "$(CURRENT)/sfx"
	@set -e; \
	manifest="$(CURRENT)/lupi_manifest.txt"; \
	for src in "$(MAKEFILE_DIR)media/sfx/"*.ogg; do \
	  name=$$(basename "$$src"); \
	  cp "$$src" "$(CURRENT)/sfx/$$name"; \
	  if ! grep -q "sfx/$$name " "$$manifest"; then \
	    size=$$(wc -c < "$(CURRENT)/sfx/$$name" | tr -d ' '); \
	    printf '%s %s sfx/%s {"type":"audio"}\n' "$$(date +%s)0000" "$$size" "$$name" >> "$$manifest"; \
	  fi; \
	done
	@test -s "$(CURRENT)/img/bg" || { echo "img/bg ausente no cartucho"; exit 1; }
	rm -f "$(LUPI)"
	cd "$(CURRENT)" && zip -r -X "$(LUPI)" .
	cd "$(CURRENT)" && zip -0 -X "$(LUPI)" img/bg
	@echo "Gerado: $(LUPI)"

clean:
	rm -rf dist .build "$(LUPI)"
