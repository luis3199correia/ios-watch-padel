# Roteiro — PadelScore

Este documento é o mapa completo do projeto: todas as fases, o que está feito, o que falta, e o
detalhe de arquitetura de cada peça — incluindo funcionalidades ainda só planeadas (não
implementadas). Complementa `decisions.md` (o *porquê* de cada decisão) com o *quê* e o *estado
atual*. Atualizar sempre que uma fase avança ou o âmbito de uma fase futura muda.

## Como ler este documento

| Símbolo | Significado |
| --- | --- |
| ✅ | Feito e validado em CI |
| ⏳ | Bloqueado — precisa de Mac (e nalguns casos, Apple Watch físico) |
| 📝 | Planeado e desenhado, ainda não implementado |

---

## Visão geral da aplicação

App nativa Apple (iPhone + Apple Watch) para registar jogos de padel.

- **iPhone**: agenda de jogos, gestão de jogadores, histórico com estatísticas.
- **Apple Watch**: pontuação ao vivo durante o jogo, com uma sessão de treino HealthKit
  (`.tennis`) a correr em paralelo do início ao fim.
- **Sincronização**: o resultado detalhado (incluindo a timeline de pontos) vai do Watch para o
  iPhone via WatchConnectivity.

### Regras de jogo suportadas

- **Formato**: à melhor de N sets (1/3/5, cada set a 6 jogos, tie-break a 6-6) · "pro-set"
  contínuo até N jogos (ex: 9, tie-break a N-1 iguais) · "Mix" (jogos consecutivos sem alvo nem
  tie-break, terminado manualmente — estilo Americano).
- **Deuce (40-40)**: vantagens clássicas · ponto de ouro (sudden death imediato) · "star point"
  (2 rondas de vantagem, à 3ª vez que chega a 40-40 o próximo ponto decide).
- Ambos configuráveis por jogo, editáveis depois.

### Estrutura do código

```
Packages/PadelKit/          Swift Package partilhado entre iOS e watchOS
  Sources/PadelCore/        Motor de pontuação puro (Swift + Foundation) — testável isoladamente
  Sources/PadelData/        Persistência SwiftData (entidades + repositórios)
  Sources/PadelUI/          Views SwiftUI + design system (sem HealthKit/WatchConnectivity/SwiftData)
PadelScore/                 Target da app iOS (a criar no Xcode, Fase 3)
PadelScore Watch App/       Target da app watchOS (a criar no Xcode, Fase 3)
docs/                       Este ficheiro + decisions.md
design/mockups/             Galeria HTML com os 15 ecrãs desenhados
```

---

## Fase 0 — Motor de pontuação, design system e ecrãs ✅

### `PadelCore` (motor puro, sem UI/HealthKit/SwiftData)

- **Fonte de verdade = log de eventos** (`PointEvent`, um por ponto). `ScoringReducer.replay`
  reconstrói o `MatchState` completo a partir do log — undo é "remover o último evento e
  repetir o replay" (decisions.md #1).
- `MatchEngine`: wrapper stateful sobre o reducer — `score(_:)`, `undoLastPoint()`,
  `endManually()` (só `.mix`), `isGoldenPointNow`/`isSetPoint`/`isMatchPoint` (derivados por
  simulação de um ponto extra, nunca duplicando a lógica de scoring).
- `MatchRules` (`format` + `deuceRule` + `tieBreakTargetPoints`), `MatchState` (`sets`,
  `currentGame`, `servingTeam`, `phase`, `startedAt`), `MatchOutcome` (`.win(Team)`/`.draw`).
- `MatchStatistics.compute`: duração, pontos totais por equipa, sequência mais longa
  (`PointStreak`), quebras de serviço por equipa (`breaksOfServeA/B`).
- `ScoreFormatter`: único ponto do motor com conhecimento de apresentação (rótulos 0/15/30/40,
  AD, etc.) — o resto da formatação vive em `PadelUI/Formatting`.

### `PadelUI` (design system + ecrãs, sem SwiftData/HealthKit/UIKit diretos)

- Theme (`PadelColor`/`PadelFont`/`PadelMetrics`/`TeamStyle`/`PlatformShims`), componentes
  (`SplitScoreboard`, `StatTile`, `OptionCard`, `CalendarStrip`, `PointTimelineDots`, etc.),
  formatação em português (`Formatting/`), structs de apresentação permanentes (`HistoryEntry`,
  `PlayerRow`, `ScheduledMatch`, `MixRoundContext`, `TeamLabels`, `WorkoutMetrics`) — desenhadas
  desde o início para serem preenchidas por `PadelData` assim que a Fase 3 o permitir.
- Efeitos secundários entram como closures (`onScore:`, `onUndo:`), nunca protocolos/DI até
  haver uma segunda implementação real.

### Ecrãs (galeria em `design/mockups/index.html`)

| # | Ecrã | Dispositivo | Estado |
| --- | --- | --- | --- |
| 1 | Agenda | iPhone | ✅ |
| 2 | Novo Jogo | iPhone | 📝 Adiado — precisa de `Player`/`Match` reais (Fase 3) |
| 3 | Histórico | iPhone | ✅ |
| 4 | Detalhe do jogo | iPhone | ✅ |
| 5 | Jogadores | iPhone | ✅ |
| 6 | Watch: Jogos | Watch | ✅ |
| 7 | Watch: pontuação ao vivo | Watch | ✅ |
| 8 | Watch: métricas ao vivo | Watch | ✅ |
| 9 | Watch: controlos | Watch | ✅ |
| 10 | Watch: resultado final | Watch | ✅ |
| 11 | Nova Sessão (Mix) | iPhone | 📝 Adiado — precisa de `Player`/`Session` reais (Fase 3) |
| 12 | Detalhe da sessão Mix | iPhone | ✅ |
| 13 | Watch: ronda Mix ao vivo | Watch | ✅ |
| 14 | Watch: controlos da ronda | Watch | ✅ |
| 15 | Watch: ronda concluída | Watch | ✅ |
| 16 | Watch: calibrar campo (a marcar um canto) | Watch | 📝 Mockup feito — SwiftUI real é Fase 4/3 |
| 17 | Watch: calibrar campo (concluído) | Watch | 📝 Mockup feito — SwiftUI real é Fase 4/3 |
| 18 | Watch: calibrar pancadas (a gravar um gesto) | Watch | 📝 Mockup feito — SwiftUI real é Fase 4/3 |
| 19 | Watch: calibrar pancadas (concluído — 11 tipos) | Watch | 📝 Mockup feito — SwiftUI real é Fase 4/3 |

`RootTabView` (iPhone): Agenda · Histórico · Jogadores · Ajustes (Ajustes fica para o target da
app, Fase 3 — é território de settings/entitlements, `PadelUI` não o possui).

**Nota**: os ecrãs 16-19 (mockups 2026-09-10/11) mostram 11 tipos de pancada — forehand, backhand,
volley, bandeja, víbora, smash, serviço, bajada (saída de vidro), rulo, chiquita, balão (lob).
O `ShotType` em `PadelCore` (`Sources/PadelCore/Court/ShotType.swift`) já tem os 11 casos
(`.serve` para "serviço", `.lob` para "balão"), com perfil por omissão sintético para cada um em
`StrokeClassifier.globalDefaultProfiles` — falta só construir as views SwiftUI destes ecrãs.

---

## Fase 2 — Persistência SwiftData ✅ (completa, até onde dá sem Mac)

### Entidades (`PadelData/Models/`)

- **`Player`**: `id`, `name`, `isMe`, `createdAt` + `participations: [MatchParticipant]`
  (`.nullify` ao apagar — o histórico mantém o `displayName`).
- **`MatchParticipant`**: `id`, `team`, `displayName`, `position` (0/1), `player: Player?`,
  `match: Match?`, `session: Session?` — exatamente um de `match`/`session` é não-nulo.
  Opositores Mix são sempre anónimos (`player: nil`, `displayName: "Adversário 1/2"`).
- **`Match`**: agendado → em curso → terminado. `rulesData`/`eventsData` (JSON, fonte de
  verdade) com mirrors filtráveis por `#Predicate` (`formatKindRaw`, `eventCount`, etc.).
  Terminado: `endedAt`/`outcomeKindRaw`/`winnerTeamRaw` + `sets: [MatchSet]` denormalizados,
  escritos uma vez — nunca mais é reconstruído via replay.
- **`MatchSet`**: `index`, `gamesA/B`, `tieBreakPointsA/B?`, `winnerTeamRaw?`, `startedAt/endedAt`.
- **`Session`** (Mix): `rounds: [Match]`, `lineup: [MatchParticipant]` ("a minha equipa",
  partilhada por todas as rondas), `targetDuration`/`targetRoundDuration` (só informativos).
- Schema versionado: `PadelSchemaV1`/`PadelMigrationPlan`, construído via
  `Schema(versionedSchema:)` + `migrationPlan:` em `PadelModelContainer.make(inMemory:)`.
- Sem `@Attribute(.unique)` em lado nenhum (decisions.md #6) — unicidade garantida no
  repositório via `ModelContext.upsert` (genérico, `IdentifiedModel.swift`).

### Camada de repositório (`PadelData/Repository/`)

- **`PlayerRepository`**: `upsert(id:name:isMe:)`, `all()` (ordenados por nome), `me()`.
- **`MatchRepository`**: `scheduleMatch(rules:scheduledAt:location:participants:)`,
  `start(_:at:)`, `saveProgress(_:engine:)` (persiste o log de eventos a cada ponto, para
  retomar um jogo em curso), `finish(_:engine:at:in:)` (escreve os `MatchSet` + resultado uma
  vez), `upcoming()`/`history()` (jogos standalone, ordenados em memória).
- **`SessionRepository`**: `start(rules:...:lineup:)` (cria a sessão + o lineup partilhado,
  sempre `Team.a`), `addRound(to:)` (ronda nova com 2 opositores anónimos `Team.b`, indexada
  sequencialmente), `finishRound` (delega em `MatchRepository.finish`), `finish(_:at:)`,
  `history()`.
- `ParticipantRoster.resolve(for:)`: une o lineup da sessão com os participantes da própria
  ronda — "quem está em campo agora", numa só chamada.
- **113/113 testes** (`swift test`) + 4/4 builds `xcodebuild` (PadelUI/PadelData × iOS/watchOS)
  verdes em CI, sem avisos de compilador.

### Nota arquitetural importante

**"Ligar os ecrãs do `PadelUI` aos dados reais do `PadelData` é trabalho da Fase 3, não da Fase
2.** `PadelUI` está proibido de importar `SwiftData`/`PadelData` diretamente (decisions.md #9,
regra 1); `PadelData` não tem razão para depender de `PadelUI`. O mapeamento entre os
resultados dos repositórios e as structs de apresentação (`HistoryEntry`, `PlayerRow`,
`ScheduledMatch`) só pode viver no *composition root* — o target real da app, que só existe a
partir da Fase 3. Por isso a Fase 2, como entregável só-CI (`swift test`/`xcodebuild`), está
**concluída**: não há mais nada para construir aqui sem um Mac.

---

## Fase 3 — Targets reais Xcode ⏳ Bloqueado (precisa de Mac)

Per decisions.md #8: os targets `PadelScore` (iOS) e `PadelScore Watch App` (watchOS) só podem
ser criados, compilados e validados num Mac com Xcode — esta máquina de desenvolvimento
(Windows) não tem toolchain Swift/Xcode.

Âmbito:
- Criar os dois targets no Xcode, adicionar `PadelCore`/`PadelUI`/`PadelData` como dependências
  de package local.
- **Composition root**: mapear os resultados de `MatchRepository`/`SessionRepository`/
  `PlayerRepository` para `HistoryEntry`/`PlayerRow`/`ScheduledMatch` (ver nota acima) — isto é
  o que finalmente liga os ecrãs 1/3/4/5/6/12 (e o resto) a dados reais em vez de amostras.
- Construir os ecrãs 2 (Novo Jogo) e 11 (Nova Sessão Mix), agora que `Player`/`Match`/`Session`
  reais existem para os alimentar.
- HealthKit: `HKWorkoutSession` + `HKLiveWorkoutBuilder`, tipo `.tennis` (decisions.md #4 —
  nunca `.paddleSports`, que é remo/SUP). Uma só sessão de treino contínua por `Session` Mix
  (decisions.md #8b) — "Terminar Partida" não pausa nem reinicia o treino.
  `WorkoutKit` fica fora de âmbito (decisions.md #5 — serve para propor treinos estruturados,
  não para gravar um jogo aberto).
- WatchConnectivity: sincronizar o resultado detalhado (incluindo a timeline de pontos) do
  Watch para o iPhone.
- `@main` entry points, code signing, conta Apple Developer Program (paga, necessária para a
  capability HealthKit no Watch).
- Sem App Group na v1 (decisions.md #7) — iPhone e Watch não partilham container; só seria
  necessário com um widget/complication que lesse dados do host diretamente.

---

## Fase 4 — Calibração de campo, heatmap e deteção de pancada 🚧 Em curso (parte testável-sem-Mac já implementada)

Ideia: calibrar o campo (andar a cada canto + rede), gerar um heatmap do jogo, e opcionalmente
usar o Watch na mão da raquete para detetar o tipo de pancada (11 tipos — ver `ShotType` abaixo),
cruzando zona do campo × tipo de pancada × resultado do ponto.

### Decisões confirmadas com o utilizador (2026-09-10)

1. **Posicionamento**: GPS contínuo durante o jogo (não marcação manual por zona).
   **Risco assumido conscientemente**: campos de padel são tipicamente fechados
   (rede/vidro à volta), o que degrada a precisão do GPS (que já ronda 3-5m a céu aberto) num
   campo de só ~20m x 10m — pode não conseguir diferenciar zonas com fiabilidade em campos
   cobertos. Mitigação de desenho: guardar sempre a amostra GPS bruta, não só a zona já
   calculada — permite trocar/corrigir o algoritmo de zona no futuro, ou adicionar correção
   manual como fallback, sem perder dados já registados nem re-arquitetar.
2. **Deteção de pancada**: heurística simples (thresholds sobre aceleração/rotação do
   CoreMotion), não um modelo de Machine Learning treinado (Create ML) — mais simples de
   construir e testar já; a precisão inicial é limitada mas o classificador é substituível
   depois sem mudar o resto da arquitetura.
3. **Calibração pessoal de pancadas** (sugestão do utilizador, aceite): em vez de limiares
   globais fixos, cada jogador faz um "setup" (grava algumas repetições de cada tipo de
   pancada) e o classificador compara swings novos contra o *seu próprio* padrão — muito mais
   fiável do que um limiar global, porque a dinâmica do swing varia bastante de jogador para
   jogador (comprimento de braço, estilo, força, orientação do relógio no pulso).
4. **Âmbito do lance registado**: **um lance por ponto** (o que decidiu o ponto), não a ralinha
   completa (todas as trocas de bola). Rastrear todos os toques exigiria classificação de
   movimento + posição contínuas e correlacionadas — um salto de complexidade não justificado
   para a v1. Isto já entrega o cruzamento pedido: zona × tipo de pancada × quem ganhou o
   ponto, ligado a um `PointEvent` existente.

### Modelo de dados detalhado

**Em `PadelCore`** ✅ implementado (`Sources/PadelCore/Court/`) — Swift puro, sem
CoreLocation/CoreMotion (mesmo princípio do #9 para HealthKit), todos os testes verdes em CI:

- `GeoPoint { latitude: Double, longitude: Double }` — evita importar `CoreLocation` no motor.
- `CourtLandmark` (enum): `.cornerNearLeft`, `.cornerNearRight`, `.cornerFarLeft`,
  `.cornerFarRight`, `.netLeft`, `.netRight`.
- `CourtCalibration { points: [CourtLandmark: GeoPoint] }` — os 6 pontos marcados a andar pelo
  campo.
- `CourtGeometry` — matemática pura que projeta lat/lon para um plano local (aproximação
  equirretangular, suficiente à escala de um campo), ajusta uma base a partir da média dos
  dois pares de arestas opostas dos 4 cantos calibrados (robusto a ruído do GPS, já que cantos
  reais nunca formam um retângulo perfeito), e mapeia uma amostra `GeoPoint` numa posição
  normalizada `(x, y) ∈ [0,1]×[0,1]` relativa ao campo (`clamp`ada se a amostra cair fora do
  retângulo calibrado). `netPositionAlongLength` localiza a rede ao longo do eixo do
  comprimento a partir dos 2 postes calibrados, em vez de assumir um ponto médio exato.
- `CourtZone` — não é um enum plano, mas 3 eixos independentes e combináveis:
  `CourtSide` (`.a`/`.b`, lado da rede), `CourtDepth` (`.net`/`.baseline`), `CourtColumn`
  (`.left`/`.right`) — 8 combinações no total, cada eixo extensível sozinho no futuro (ex: um
  3º nível de profundidade).
- `ShotType` (enum, 11 casos): `.forehand`, `.backhand`, `.smash`, `.volley`, `.bandeja`,
  `.vibora`, `.serve`, `.bajada`, `.rulo`, `.chiquita`, `.lob`. `StrokeClassifier.globalDefaultProfiles`
  tem um perfil por omissão sintético para cada um dos 11.
- `MotionSample` — vetor de características resumido de um swing: pico de aceleração, taxa de
  rotação, direção predominante, duração do gesto — com uma métrica de distância própria
  (escalada por eixo, com wraparound correto no ângulo 0°/360°). (A extração destas
  características a partir de `CMDeviceMotion` bruto continua a ser trabalho de Fase
  4/hardware; a struct e a lógica que a consome já são puras e testadas.)
- `StrokeProfile { shotType: ShotType, referenceSamples: [MotionSample] }` — o "padrão"
  pessoal de cada jogador por tipo de pancada, construído no setup; a distância a uma amostra
  nova é a do vizinho mais próximo entre as amostras de referência, não a média.
- `StrokeClassifier` — dado um `MotionSample` novo, compara-o (nearest-neighbor) aos
  `StrokeProfile` fornecidos; qualquer tipo de pancada sem perfil pessoal cai automaticamente
  no **`globalDefaultProfiles`** (limiares fixos "clássicos", um ponto de partida a afinar
  quando houver swings reais) — a funcionalidade funciona desde o primeiro uso.
- `ShotHeatmapAggregator`/`ZoneCount` — conta ocorrências por `CourtZone`, puro, sem SwiftData;
  é isto que a visualização do heatmap em `PadelUI` (por construir) vai consumir.

**Em `PadelData`** ✅ implementado (`Sources/PadelData/Models/` + `Repository/`) — mesmo padrão
de blob JSON + inverse explícito já usado por `Match`/`Session`/`Player`:

- Entidade `Shot`: `id`, `pointEventID: UUID` (liga ao `PointEvent` que este lance decidiu),
  `zone: CourtZone` (JSON), `rawSample: GeoPoint` (JSON, guardado sempre — ver risco acima),
  `strokeType: ShotType?`, `strokeConfidence: Double?`, `team: Team`, `recordedAt: Date`,
  `match: Match?` (cascade, `Match.shots` é o inverso).
- Entidade `CourtCalibrationRecord`: `location: String` (mesma convenção de `Match`/`Session`),
  `calibration: CourtCalibration` (JSON) — uma por `location`, reutilizada entre jogos no mesmo
  campo.
- Entidade `StrokeProfileRecord`: `shotType`, `referenceSamples: [MotionSample]` (JSON),
  `player: Player?` (cascade, `Player.strokeProfiles` é o inverso).
- `ShotRepository` (`record`/`shots(for:)`), `CourtCalibrationRepository`
  (`save`/`find(location:)`), `StrokeProfileRepository` (`save`/`find`/`profiles(for:)` — estes
  dois últimos lêem/escrevem via `Player.strokeProfiles` diretamente, nunca um
  `FetchDescriptor`, mesmo padrão de `ParticipantRoster`).

**Em `PadelUI`** 📝 por construir (com dados sintéticos em testes/previews, como todo o resto):

- Ecrã/fluxo de calibração do campo (Watch): "vai ao canto perto-esquerda e toca", repetido
  para os 6 pontos.
- Ecrã/fluxo de setup de pancadas (Watch): "faz 3 forehands", repetido para os 11 tipos.
- Visualização de heatmap (iPhone, `Canvas` SwiftUI): pontos/zonas sobre um diagrama do campo,
  coloridos por densidade e/ou por resultado do ponto (ganho/perdido) — consome
  `ShotHeatmapAggregator.aggregate` já implementado.

### O que dá para construir e testar já (sem Mac, via `swift test`/CI)

- ✅ `GeoPoint`, `CourtLandmark`, `CourtCalibration`, `CourtGeometry`, `CourtZone` (testado com
  coordenadas sintéticas).
- ✅ `ShotType`, `MotionSample`, `StrokeProfile`, `StrokeClassifier`, `ShotHeatmapAggregator`
  (testado com vetores de características sintéticos).
- ✅ As entidades e repositórios de `PadelData` (`Shot`, `CourtCalibrationRecord`,
  `StrokeProfileRecord` + os repositórios correspondentes).
- 📝 A visualização do heatmap em `PadelUI`, alimentada por dados sintéticos — ainda por
  construir.

### O que fica bloqueado até Mac + Apple Watch físico

- Captura real de `CoreLocation` durante a calibração e o jogo.
- Captura real de `CoreMotion` (`CMDeviceMotion`) durante os swings, e a extração real das
  características de `MotionSample` a partir dos dados brutos dos sensores.
- Afinação dos limiares do perfil global por omissão com swings reais.
- Validação em campo real de quão bem o GPS diferencia zonas dentro de um campo coberto —
  pode motivar revisitar a Decisão 1 acima.

---

## Onde estamos agora (2026-09-11)

Fases 0 e 2 estão **concluídas e validadas em CI**. Fase 3 está **bloqueada** — precisa de Mac,
e é o único caminho para desbloquear os ecrãs 2/11 e ligar tudo a dados reais. Fase 4 tem a
parte testável-sem-Mac **implementada e validada em CI** (geometria/classificador em
`PadelCore` — `ShotType` já com os 11 tipos de pancada, entidades/repositórios em `PadelData`);
falta ainda construir em `PadelUI` (dados sintéticos) as views de calibração de campo/pancadas
e a visualização de heatmap, para fechar tudo o que dá para fazer sem Mac + Watch físico.

---

## Referências

- `decisions.md` — o porquê de cada decisão de arquitetura, com mais detalhe de implementação
  nalguns pontos do que este ficheiro.
- `README.md` — visão geral rápida e instruções de desenvolvimento.
- `design/mockups/index.html` — os 15 ecrãs desenhados, com o número/nome usado neste documento.
