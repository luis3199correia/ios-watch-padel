# PadelScore

App nativa Apple (iPhone + Apple Watch) para registar jogos de padel.

## Visão geral

- **iPhone**: agenda de jogos (calendário), gestão de jogadores, histórico de jogos com estatísticas.
- **Apple Watch**: pontuação ao vivo durante o jogo, com uma sessão de treino HealthKit a correr em paralelo (frequência cardíaca, calorias) desde o início até ao fim do jogo.
- **Sincronização**: o resultado detalhado do jogo (incluindo a timeline de pontos) é enviado do Watch para o iPhone via WatchConnectivity e fica disponível no histórico para análise posterior.

## Estrutura

```
Packages/PadelKit/     Swift Package partilhado entre iOS e watchOS
  Sources/PadelCore/   Motor de pontuação puro (Swift + Foundation, sem UI/HealthKit) — testável isoladamente
  Sources/PadelUI/     Views SwiftUI + design system (sem HealthKit/SwiftData) — ver docs/decisions.md #9
PadelScore/            Target da app iOS (a criar no Xcode, no Mac)
PadelScore Watch App/  Target da app watchOS (a criar no Xcode, no Mac)
docs/                  Decisões de arquitetura e checklists de teste manual
```

## Requisitos

- iOS 17+ / watchOS 10+
- Xcode 16+ (macOS) — necessário para compilar os targets de app; `Packages/PadelKit` compila e testa de forma independente com `swift test`.
- Conta Apple Developer Program (paga) para a capability HealthKit no Watch.

## Regras de pontuação suportadas

- **Formato da partida**: à melhor de N sets (1/3/5, cada set a 6 jogos com tie-break a 6-6) **ou** "pro-set" contínuo até N jogos (ex: 9), com 2 de margem e tie-break a N-1 iguais (ex: 8-8) — configurável e editável por jogo.
- **Resolução de deuce (40-40)**: vantagens clássicas, ponto de ouro (sudden death imediato), ou "star point" (permite 2 rondas de vantagem; à 3ª vez que o jogo chega a 40-40, o próximo ponto decide sem mais vantagens) — configurável e editável por jogo.

Ver `docs/decisions.md` para o detalhe de cada decisão de arquitetura.

## Desenvolvimento

```bash
cd Packages/PadelKit
swift test
```

Este comando não corre em Windows (sem toolchain Swift/Xcode) — validar no Mac ou através do workflow de CI em `.github/workflows/ci.yml`.
