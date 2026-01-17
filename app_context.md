# Contexto do Aplicativo (App Context)

Este arquivo descreve o funcionamento, regras de negócio e objetivos do aplicativo **MakePolyrhythm**.
Ele serve como fonte de verdade para LLMs entenderem **o que** deve ser construído.

## 1. Visão Geral do Produto
O MakePolyrhythm é um aplicativo focado em pessoas com TDAH e autismo nível 1, onde possibilita o usuário montar animações de batidas, notas musicais, sons de sintetizadores e cores vibrantes para ajudar na terapia cognitiva e estimular a concentração.

Exemplos de animações com sons que o usuário pode fazer:
- https://www.youtube.com/shorts/rfipj4QslbU
- https://www.youtube.com/shorts/0QZkFPVXDxs
- https://www.youtube.com/shorts/ZLc_WtgX8Zw
- https://www.youtube.com/shorts/OsAlMi_uzvw
- https://www.youtube.com/watch?v=Lxs4cvSximc
- https://www.youtube.com/shorts/OTm_vunD0JY
- https://www.youtube.com/shorts/Nz3DMpAelTE


## 2. Funcionalidades Principais (Core Features)
- **Editor de Animação em Tempo Real**: Permite montar e configurar animações enquanto elas rodam.
- **Elementos Personalizáveis**:
  - Pontos/Bolas (emissores de som/movimento).
  - Objetos/Formas (paredes ou obstáculos que geram colisão).
  - Cores vibrantes (paletas estimulantes).
- **Exportação**:
  - Salvar projetos localmente.
  - Exportar composições (formato de vídeo ou áudio).

## 3. Regras de Negócio e Lógica (Physics & Audio)
- **Física do Mundo**:
  - Ambiente 2D com gravidade zero (padrão) ou configurável.
  - Colisões perfeitamente elásticas (sem perda de energia) para manter o ritmo constante.
  - "Pontos" se movem com velocidade constante até colidirem.
- **Interação Musical**:
  - Cada colisão entre um "Ponto" e um "Objeto" dispara uma nota musical.
  - A nota depende das propriedades do Objeto (ex: tamanho, tipo) ou do Ponto.
  - **Polirritmia**: Criada pela interação de múltiplos pontos com velocidades/trajetórias diferentes.
- **Customização**:
  - Usuário pode adicionar N pontos e N objetos.
  - Controle de velocidade global e individual.

## 4. Diretrizes Técnicas (Sugestão de Implementação)
- **Engine Gráfica**: **SpriteKit** (Recomendado para melhor performance com muitas partículas e física nativa).
- **Engine de Áudio**: **AVAudioEngine** para síntese sonora em tempo real e baixa latência.
- **Interface**: **SwiftUI** para controles e overlays, hospedando uma `SpriteView` para a animação.

## 5. Interface e UX
- **Splash Screen**: Introdução visual suave.
- **Tela Principal (Editor)**:
  - Área de canvas (animação).
  - Painel de controles flutuante ou retrátil para não obstruir a visão da animação.
  - Feedback visual imediato ao adicionar/remover elementos.
