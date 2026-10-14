
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STAGE := $(MAKEFILE_DIR).build/src
CURRENT := $(MAKEFILE_DIR)dist/current
LUPI := $(MAKEFILE_DIR)duckhunt.lupi

SDK := hldtux/lupinho-sdk
WEB := $(MAKEFILE_DIR).build/webgame

.PHONY: game/codec lupi web clean

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

web: lupi
	rm -rf "$(WEB)"
	mkdir -p "$(WEB)"
	docker run --rm --entrypoint bash \
		-v "$(LUPI):/game.lupi:ro" \
		-v "$(WEB):/out" \
		$(SDK) \
		-lc 'set -eo pipefail; source /opt/emsdk/emsdk_env.sh; set -u; make -C /lupinho/lupinho/src web-game GAME_PATH=/game.lupi; cp -a /lupinho/lupinho/dist/webgame/. /out/'
	cp "$(MAKEFILE_DIR)media/web/fullscreen.css" "$(WEB)/fullscreen.css"
	perl -i -pe 's{</head>}{<link rel="stylesheet" href="fullscreen.css"></head>}' "$(WEB)/game.html"
	cp "$(WEB)/game.html" "$(WEB)/index.html"
	touch "$(WEB)/.nojekyll"

clean:
	rm -rf dist .build "$(LUPI)"
