# Blackwood

RPG de ação top-down feito em **Godot 4.7** — combate, gold drop, trilhas e melhorias.

Escolha um campeão, vença **3 fases x 5 ondas (15 ondas)**, com mini-bosses, bosses, elites, loja, itens e desbloqueio progressivo de skills.

## Jogar (Windows)

Baixe a última versão em **[Releases](https://github.com/Diasprogramador/blackwood/releases)**, extraia o zip e rode `blackwood.exe`. Para o co-op online, os dois precisam da mesma versão: um hospeda em **👥 Multiplayer** e passa o IP (ou usem Radmin VPN/ZeroTier).

## Jogar (Android)

Baixe o `.apk` da **[Releases](https://github.com/Diasprogramador/blackwood/releases)**, instale (permita fontes desconhecidas) e jogue em **paisagem**: joystick virtual à esquerda, botões de ataque/skills à direita. O co-op funciona entre PC e celular na mesma versão.

## Como rodar

1. Instale o **Godot 4.7** (renderer `gl_compatibility`).
2. Clone o repositório:
   ```sh
   git clone https://github.com/Diasprogramador/blackwood.git
   ```
3. Abra a pasta no Godot e aperte **F5** (cena principal: `res://scenes/main.tscn`).

Sprites originais do Canva em `assets/sprites/original/`, ícones vetoriais próprios e cenário/áudio procedurais. Nenhuma dependência de rede para jogar solo.

## Controles (padrão, remapeáveis em Configurações)

| Ação | Tecla |
|---|---|
| Mover | WASD / Setas |
| Ataque básico | Espaço |
| Esquiva (solo) | Shift |
| Habilidades 1–5 | 1 2 3 4 5 |
| Canalizar mana | E (parado) |
| Usar item | Q |
| Loja | TAB |
| Pausar | ESC |
| Confirmar / jogar de novo | ENTER / R (game over e vitória) |

Progresso (`essência ◆`) e configurações ficam em `user://` — sobreviva às ondas para desbloquear skills no menu.

## Combate e progressão

O ataque básico é **automático**, sem custo de mana. Espaço também permite
atacar manualmente; habilidades usam as teclas 1–5. No solo, Shift executa uma
esquiva na direção do movimento (ou na última direção), com recarga de 1,6 s.
No touch, o botão principal é ESQUIVA e o layout continua personalizável.

Os cristais de XP oferecem uma escolha gratuita de poder por nível no solo.
Escolha entre três dádivas com o combate pausado: ataque, velocidade, golpes
ramificados, aura ou vida. Cada poder tem limite de acúmulo. A loja vende itens;
a tabela de atributos comprados com ouro foi removida. A vida base cresce
linearmente, com recuperação limitada ao subir de nível. A primeira subida exige
36 XP. A loja da partida e os desbloqueios permanentes continuam disponíveis.

No desktop, clique nas habilidades, esquiva, item, mana, loja e pausa no HUD.
Passe o mouse sobre uma habilidade para consultar custo, recarga e descrição.
O co-op continua com XP compartilhada e ações enviadas ao host; a esquiva
permanece exclusiva do solo.

## Otimização e validação

- Chão, árvores e pedras procedurais são rasterizados uma vez e reutilizados.
  Profundidade, escala, colisão e transparência de oclusão continuam por objeto.
  Uma troca de bioma refaz o chão e o atlas dos props com a arte da região.
- A água desenha apenas a região da câmera. Separação de inimigos consulta uma
  grade espacial, em vez de comparar todos os pares do mapa.
- Inimigos comuns mostram barras quando feridos; nomes ficam para elites e chefes.
  Textos de combate e vozes de áudio têm limites para evitar rajadas sem controle.
- A pausa congela movimento e recargas. Recompensas por morte são concedidas uma
  única vez, mesmo quando sinal e feedback de ataque chegam ao mesmo handler.

Cada região tem arquitetura, vegetação e habitantes próprios: máscaras de casca
e árvores antigas na Floresta Verde; obsidiana, fornalhas e armaduras de escória
na Terra Queimada; salgueiros, cristais de jade e criaturas afogadas no Pântano
Sombrio. São 18 designs de inimigos (seis por região), com poses em atlas.
Os detalhes de solo são decorativos e preservam os corredores de navegação.

Verificações de comportamento:

```sh
godot --headless --path . --script res://tests/survival_checks.gd
godot --headless --path . --script res://tests/update_checks.gd
```

Verificação visual dos três biomas, bestiário e troca de atlas (pasta de saída existente):

```sh
godot --path . --script res://tests/biome_checks.gd -- exports/biomes
```

Verificações gráficas e encontro artificial de estresse com 48 inimigos:

```sh
godot --path . --audio-driver Dummy --fixed-fps 60 --script res://tests/render_checks.gd -- <pasta-de-capturas>
```

Esse teste usa vida artificialmente alta e uma cota de onda ampliada para medir
combate sem derrota ou gravação de progresso. Não representa o balanceamento
normal. Desempenho em Android e co-op com dois aparelhos ainda requer teste real.

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

## Atualização 0.7.0 — Fronteira de Ferro

Seleção de mapas ilustrada, dificuldades com seus multiplicadores e HUD com
retrato, vida perdida animada, progresso das cinco ondas e recargas circulares.
Ataques têm lâminas em camadas, rastros, fragmentos e impactos por personagem.
As escolhas de melhorias gratuitas foram removidas para recuperar o desafio.

Teste gráfico e de interação (pasta de saída existente):

```sh
godot --path . --script res://tests/interface_checks.gd -- exports/interface
```

## Atualização 0.6.0 — Três Reinos

Os três mapas têm árvores, pedras, trilhas, água e marcas no solo próprios.
Cada região também possui seis designs de NPCs, incluindo os chefes, com
nomes e detalhes de anatomia/equipamento exclusivos. A arte estática fica em
atlas para manter baixo o custo de desenhar hordas. Consulte o [changelog](CHANGELOG.md).

## Atualização 0.5.0 — Ecos do Bosque

- Menu com os guardiões originais, brasões, ícones próprios e paleta do bosque.
- Ataques com rastros de lâmina, magia, vento e flechas; habilidades com efeitos
  próprios por personagem e slot. Efeitos replicados no co-op da mesma versão.
- Inimigos contornam árvores, lagos e pedras por rotas compartilhadas. A separação
  respeita o corpo inteiro e a esquiva não atravessa obstáculos com passos longos.
- Personagem olha na direção do movimento; parado, a esquiva preserva a última
  direção, inclusive vertical. O cursor não controla a orientação.
- **Configurações → Personalizar HUD**: arraste joystick e botões, ajuste tamanho
  e opacidade individualmente e escolha Salvar. Cancelar descarta a edição;
  Restaurar prepara o layout padrão, que só é aplicado ao salvar. Posições são
  proporcionais à tela e os alvos de toque acompanham as alterações.
- Controles soltam entradas ao pausar, ocultar ou perder o foco da aplicação.

Validação adicional: `godot --headless --path . --script res://tests/update_checks.gd`.
Cobre um obstáculo em U, nove rotas de florestas geradas, colisão da esquiva,
orientação vertical, arraste/escala do HUD e serialização da personalização.
Os pacotes Android mantêm o identificador e certificado da versão 0.4.0.
A instalação e o co-op em aparelhos Android físicos ainda precisam de teste real.

## Correção 0.7.1 — Dádivas do Bosque
A remoção da 0.7.0 foi corrigida: voltam as escolhas gratuitas de nível no solo,
com cartas ilustradas, graus e controles por toque, mouse e teclado. Sai a tabela
de melhorias por ouro, inclusive seus atalhos e pedidos de rede. A loja mantém
itens, preços visíveis e botão de fechar. O co-op mantém o fluxo contínuo existente.

## Áudio — 0.7.2
A trilha original **Vozes do Bosque** toca no login e nos menus. Ela desaparece
gradualmente ao iniciar uma partida. Música, efeitos e volume geral podem ser
ajustados separadamente nas configurações. Os ataques têm timbres por classe;
esquiva, dano, poções e resultados ganharam novos efeitos. Código de síntese e
origem dos arquivos em `tools/generate_audio.py` e `assets/audio/README.md`.
