# Blackwood 0.5.0 — Ecos do Bosque

- Novo menu com os personagens originais do Canva, paleta do bosque e ícones próprios.
- HUD mobile personalizável: arraste joystick e botões; altere tamanho e opacidade
  de cada controle em Configurações → Personalizar HUD. Salvar, cancelar e restaurar.
- Rotas de perseguição compartilhadas: inimigos contornam lagos, árvores e pedras.
  Separação respeita o raio do corpo; esquiva testa todo o percurso contra obstáculos.
- Orientação pelo movimento, sem seguir o mouse, e esquiva na última direção usada.
- Rastros de ataques e efeitos distintos por personagem e habilidade, inclusive no co-op.
- Ataque básico automático, cristais de XP e escolhas de evolução durante a partida solo.
- Cenário estático em cache e limites de efeitos/áudio para reduzir custo das hordas.

## Instalação

Windows: extraia `blackwood-windows.zip` e execute `blackwood.exe`, mantendo
`blackwood.pck` ao lado. Android ARM64: instale `blackwood.apk` sobre a versão
anterior. O pacote mantém o identificador e o certificado de 0.4.0, com código
de versão incrementado para 4. Não é necessário desinstalar para atualizar.
Todos os participantes do co-op devem usar a versão 0.5.0.

## Validação

- 35 verificações de sobrevivência e 20 verificações de navegação/HUD aprovadas.
- Capturas conferidas em janela desktop e paisagem 960 × 540; 30 efeitos de ataque renderizados.
- Encontro artificial com 48 inimigos: 14,37 ms médios, 21,67 ms p95 neste computador.
  Esse teste mede uma cena de estresse, não garante desempenho em outros aparelhos.
- Executável Windows exportado iniciado sem erros; APK verificado e certificado
  comparado ao arquivo público da versão 0.4.0.
- Instalação em Android físico e co-op entre aparelhos ainda não validados nesta rodada.
