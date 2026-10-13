## 0.7.1 — Dádivas do Bosque

- Corrige a interpretação da atualização anterior: remove a tabela de atributos
  comprados por ouro e restaura escolhas gratuitas ao subir de nível no solo.
- Nova tela de dádivas com símbolos desenhados, descrição, grau e limite,
  seleção por teclado/mouse/toque e fila para múltiplos níveis.
- Compras antigas de atributos bloqueadas também pelo backend/rede.
- Loja de itens com preços corrigidos, foco visível e botão de fechar no mobile.
- Mantém crescimento linear e recuperação limitada; co-op segue contínuo.
- Windows e Android (versionCode 7), preservando assinatura de atualização.

# Blackwood 0.7.0 — Fronteira de Ferro

- Seleção de mapas com miniaturas dos biomas, seus chefes e indicação de bloqueio.
- Dificuldades com selos de ameaça e multiplicadores reais de vida, dano, horda e ouro.
- HUD com retrato, placas recortadas, transição de vida perdida, progresso das
  cinco ondas e recargas circulares. Ações clicáveis no desktop e descrições
  das habilidades ao passar o mouse; os controles mobile personalizados continuam.
- Ataques com lâminas em camadas, rastros de energia, fragmentos e impactos
  específicos por personagem. Detalhes reduzidos na qualidade baixa.
- Removidas as escolhas de melhorias gratuitas ao subir de nível. A luta continua
  sem pausa, a vida máxima cresce linearmente e o nível recupera apenas a vida
  e mana acrescentadas. Lojas e desbloqueios permanentes foram preservados.
- Cliques de combate do HUD no cliente co-op seguem o envio de comandos ao host.

## Instalação

Windows: extraia `blackwood-windows.zip` e execute `blackwood.exe`, mantendo
`blackwood.pck` ao lado. Android ARM64: instale `blackwood.apk` sobre a versão
anterior. Identificador e certificado mantidos; código de versão 6.
Todos os participantes do co-op devem usar a versão 0.7.0.

## Validação

- 28 verificações de combate/progressão e 20 de navegação/HUD aprovadas.
- Seleção bloqueada/desbloqueada, clique em mapa/dificuldade, pausa, loja,
  canalização e envio único de comando co-op testados.
- Capturas em desktop e 960 × 540; 180 amostras de efeitos em duas qualidades.
- Executável Windows exportado iniciado sem erros; APK ARM64 com assinatura
  v2/v3 verificada e certificado igual ao das versões anteriores.
- Encontro artificial com 48 inimigos: 14,95 ms médios e 28,62 ms p95 neste
  computador, com atributos ofensivos normais. Não garante desempenho em outros aparelhos.
- Instalação em Android físico e sessão co-op entre aparelhos não testadas nesta rodada.

---

# Blackwood 0.6.0 — Três Reinos

- Floresta Verde com árvores de copas sobrepostas, pedras rúnicas, musgo e samambaias.
- Terra Queimada com troncos carbonizados, obsidiana, trilhas de lajes e brasas.
- Pântano Sombrio com salgueiros, cristais de jade, passagens antigas e água espectral.
- 18 designs de NPCs, seis por região: máscaras, armaduras, galhadas, asas,
  lanternas e carapaças próprios. Chefes também mudam de aparência e nome.
- Silhuetas com sombreado, textura e poses de movimento em atlas; destaque para elites.
- Símbolos regionais na praça central e paletas próprias de terreno e água.
- O atlas de árvores e pedras acompanha a troca de região, inclusive ao voltar
  para um mapa anterior. Os adornos do chão preservam a navegação existente.

## Instalação

Windows: extraia `blackwood-windows.zip` e execute `blackwood.exe`, mantendo
`blackwood.pck` ao lado. Android ARM64: instale `blackwood.apk` sobre a versão
anterior. Identificador e certificado mantidos; código de versão incrementado
para 5. Todos os participantes do co-op devem usar a versão 0.6.0.

## Validação

- 35 verificações de sobrevivência e 20 de navegação/HUD aprovadas.
- Teste gráfico de quatro transições (floresta → queimada → pântano → floresta),
  com comparação dos atlas e conferência visual dos 18 NPCs.
- Encontro com 48 inimigos: 11,69 ms médios e 21,12 ms p95 neste computador.
  O resultado não garante o mesmo desempenho em outros aparelhos.
- Executável Windows exportado iniciado sem erros.
- APK ARM64 verificado com assinatura v2/v3, versão 0.6.0/código 5 e o
  mesmo certificado das versões anteriores.
- Instalação em Android físico e co-op entre aparelhos não testados nesta rodada.

---

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
