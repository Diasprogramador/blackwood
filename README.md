# Blackwood

RPG de ação top-down feito em **Godot 4.7** — combate, gold drop, trilhas e melhorias.

Escolha um campeão, vença **3 fases x 5 ondas (15 ondas)**, com mini-bosses, bosses, elites, loja, itens e desbloqueio progressivo de skills.

## Como rodar

1. Instale o **Godot 4.7** (renderer `gl_compatibility`).
2. Clone o repositório:
   ```sh
   git clone https://github.com/Diasprogramador/blackwood.git
   ```
3. Abra a pasta no Godot e aperte **F5** (cena principal: `res://scenes/main.tscn`).

Nenhuma dependência externa — sprites e áudio são procedurais/gerados via código (`scripts/sprite_kit.gd`, `scripts/art_util.gd`, `scripts/sfx.gd`).

## Controles (padrão, remapeáveis em Configurações)

| Ação | Tecla |
|---|---|
| Mover | WASD / Setas |
| Ataque básico | Espaço |
| Habilidades 1–5 | 1 2 3 4 5 |
| Canalizar mana | E (parado) |
| Usar item | Q |
| Loja | TAB |
| Pausar | ESC |
| Confirmar / jogar de novo | ENTER / R (game over e vitória) |

Progresso (`essência ◆`) e configurações ficam em `user://` — sobreviva às ondas para desbloquear skills no menu.

## Estrutura

```
project.godot          # Blackwood, 960x640, main = scenes/main.tscn
scenes/main.tscn
scripts/               # main.gd, player.gd, enemy.gd, combat_system.gd,
                       # champ_data.gd, stage_data.gd, world.gd, hud.gd,
                       # shop_ui.gd, champ_select.gd, stage_menu.gd, ...
assets/sprites/        # sprites dos campeões/inimigos (.png + .import)
theme/game_theme.tres
```

- `scripts/main.gd` — estados (menu → champ → stage → play → pause/shop → gameover/victory), waves, spawn, gold drop.
- `scripts/stage_data.gd` — fases, dificuldades, cotas de onda, essências e desbloqueios.
- `scripts/champ_data.gd` — campeões, roles e skills.
- `scripts/game_settings.gd` — volumes, teclas, fullscreen e screen shake (`user://rpg_league_settings.cfg`).
