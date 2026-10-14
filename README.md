# Duck Hunt

Port de Duck Hunt para o console Lupi: tela 480×270, 60 fps, Lua.

Dois patos por vez, três tiros. Cada acerto vale 10 pontos. A rodada tem dez patos; quatro erros encerram o jogo.

## Rodar

Precisa de Lua 5.5 e do submódulo `lupi-codec`.

```sh
git submodule update --init
make lupi
lupinho duckhunt.lupi
```



https://github.com/user-attachments/assets/5a3fb60d-20ed-470f-844d-a52f51b28c05



`make lupi` monta o cartucho e grava `duckhunt.lupi` (um zip). `make game/codec` deixa a mesma pasta aberta em `dist/current`. `make clean` apaga `duckhunt.lupi`, `dist/` e `.build/`.

Cada push na `main` publica o cartucho em [duckhunt.lupi](https://github.com/humbertodias/lupi-duckhunt/releases/latest/download/duckhunt.lupi).

## Controles

| Ação | Console | Teclado (lupinho) | Mouse |
| --- | --- | --- | --- |
| Mirar | Direcional | W A S D | Ponteiro |
| Atirar | B | K | Botão esquerdo |
| Recomeçar | A ou B | J ou K | Botão esquerdo |

## Áudio

Os efeitos saem por `sfx.fx` e as vinhetas por `sfx.music`. Os arquivos ficam em `media/sfx/` e entram no cartucho como `sfx/*.ogg`.

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
