# Vozes do Bosque

Composição e síntese originais para Blackwood, geradas por `tools/generate_audio.py`.
Sem gravações externas ou músicas de terceiros. Reproduzíveis com Python padrão.

Trilha: 16 compassos, 84 BPM, ré menor; harpa sintetizada, pad de cordas,
baixo e pulso de madeira. Delay circular para preservar a cauda no loop.
Duração: aproximadamente 45,7 segundos, estéreo, PCM de 16 bits a 22050 Hz.

18 efeitos mono pré-renderizados: impactos, cinco classes, esquiva, projéteis,
poção, moedas, interface e resultados. Importação QOA do Godot para reduzir peso.
Nenhum áudio é sintetizado dentro do loop de combate. Volume independente nos
buses Music e SFX; limite de 12 vozes e intervalo por efeito de 65 ms.
