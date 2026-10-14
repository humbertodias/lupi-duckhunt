# Desenvolvimento

Tela 480×270, 60 fps, Lua. O cartucho é um zip chamado `duckhunt.lupi`.

## Montar

Precisa de Lua 5.5, `zip` e do submódulo `lupi-codec`. O codec chama `magick` para ler os PNG.

```sh
git submodule update --init
make lupi
lupinho duckhunt.lupi
```

| Alvo | Resultado |
| --- | --- |
| `make lupi` | `duckhunt.lupi` |
| `make web` | jogo web em `.build/webgame/`, via `hldtux/lupinho-sdk` |
| `make game/codec` | pasta aberta em `dist/current` |
| `make clean` | apaga `duckhunt.lupi`, `dist/` e `.build/` |

`make game/codec` copia `game.lua`, `media/img/` e `media/sfx/` para `.build/src` e roda `lupi-codec`. Os `.ogg` são recolocados no release se o codec não os mantiver.

O fundo `img/bg` entra no zip sem compressão. O lupinho falha ao inflar um arquivo muito comprimido acima de cerca de 32 KB, e o fundo tem 129600 bytes.

Cada push na `main` publica o cartucho em [duckhunt.lupi](https://github.com/humbertodias/lupi-duckhunt/releases/latest/download/duckhunt.lupi) (`.github/workflows/release.yml`) e a versão web em [humbertodias.github.io/lupi-duckhunt](https://humbertodias.github.io/lupi-duckhunt/) (`.github/workflows/pages.yml`).

`make web` monta o `.lupi` e pede ao container `hldtux/lupinho-sdk` o `make web-game`, que embute o cartucho no Lupinho em WebAssembly. A pasta `.build/webgame` recebe `media/web/fullscreen.css` ligado no `game.html`.

No Ubuntu o ImageMagick 6 não tem o comando `magick`; os workflows instalam um atalho para `identify` e `convert`. O Pages do repositório precisa estar em GitHub Actions.

## Áudio

Efeitos em `sfx.fx`, vinhetas em `sfx.music`. Os arquivos ficam em `media/sfx/` e entram no cartucho como `sfx/*.ogg`, sem extensão na chamada.

| Chamada | Quando |
| --- | --- |
| `sfx.fx("sfx/bark")` | Cachorro late na intro |
| `sfx.fx("sfx/blast")` | Tiro |
| `sfx.fx("sfx/point")` | Acerto |
| `sfx.fx("sfx/quack")` | Pato voando |
| `sfx.fx("sfx/drop")` | Pato no chão |
| `sfx.fx("sfx/hit")` | Cachorro mostra os patos |
| `sfx.fx("sfx/flyaway")` | Cachorro ri |
| `sfx.music("sfx/next-round")` | Rodada cumprida |
| `sfx.music("sfx/gameover")` | Fim de jogo |

## Arquivos

- `game.lua` — jogo
- `media/img/` — sprites (fundo, mira, cachorro, pato, HUD)
- `media/sfx/` — sons
- `lupi-codec/` — converte o estágio em cartucho
