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

## Combate e builds de sobrevivência

O ataque básico agora é **automático**, sem custo de mana. Espaço continua
disponível para dispará-lo manualmente; habilidades continuam nas teclas 1–5.
No solo, Shift executa uma esquiva na direção do movimento (ou para onde o
personagem olha), com recarga de 1,6 s. No touch, o botão principal vira ESQUIVA.

Inimigos deixam cristais de XP no solo. Aproxime-se para atraí-los e subir de
nível; cada nível pausa a partida e oferece três melhorias aleatórias, escolhidas
com clique/toque ou teclas 1, 2 e 3. Poder, velocidade de ataque, movimento,
golpes em vários alvos, aura de espinhos e vida podem ser combinados. Os limites
de acúmulo são respeitados; a build é reiniciada a cada partida e não custa essência.
A primeira evolução exige 36 XP. As ondas têm mais inimigos e reforços mais rápidos.

O co-op mantém a experiência compartilhada: básico automático, XP direto e bônus
de nível existentes. As escolhas de build e a esquiva são, por enquanto, do solo;
assim não são enviadas mudanças de estado que o protocolo atual não replica.

## Otimização e validação

- Chão, árvores e pedras procedurais são rasterizados uma vez e reutilizados.
  Profundidade, escala, colisão e transparência de oclusão continuam por objeto.
  Uma troca de mapa invalida o chão e reutiliza o atlas dos props.
- A água desenha apenas a região da câmera. Separação de inimigos consulta uma
  grade espacial, em vez de comparar todos os pares do mapa.
- Inimigos comuns mostram barras quando feridos; nomes ficam para elites e chefes.
  Textos de combate e vozes de áudio têm limites para evitar rajadas sem controle.
- A pausa congela movimento e recargas. Recompensas por morte são concedidas uma
  única vez, mesmo quando sinal e feedback de ataque chegam ao mesmo handler.

Verificações de comportamento:

```sh
godot --headless --path . --script res://tests/survival_checks.gd
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
