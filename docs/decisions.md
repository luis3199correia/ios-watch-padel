# Decisões de Arquitetura — PadelScore

Registo das decisões tomadas com o utilizador e das razões por trás delas. Atualizar sempre que uma decisão relevante mudar.

## 1. Event log como fonte de verdade

O placar de um jogo nunca é guardado diretamente — é sempre **derivado** de um log ordenado de eventos (`PointEvent`, um por ponto marcado). `ScoringReducer.replay(events:)` reconstrói o estado completo (`MatchState`) a partir do log.

**Porquê**: torna o "desfazer último ponto" trivialmente correto (basta remover o último evento e repetir o replay) e dá a timeline do jogo de graça, sem estrutura adicional. Qualquer bug de projeção é recuperável por reprojeção, sem perda de dados.

## 2. Formato da partida: por sets ou pro-set

`MatchFormat` tem dois casos:
- `.sets(bestOf:)` — partida à melhor de N sets, cada set a 6 jogos, tie-break a 6-6.
- `.proSet(targetGames:)` — partida como um único "set" contínuo até `targetGames` jogos (ex: 9), com 2 de margem, tie-break a `targetGames - 1` iguais (ex: 8-8).

Escolhido por jogo pelo utilizador ao criar no calendário; editável depois. Ambos os formatos reutilizam a mesma lógica de `SetScoring`/`TieBreakScoring` — `.proSet` é modelado internamente como uma partida que só precisa de 1 set para terminar, cujo "set" tem como alvo `targetGames` em vez dos habituais 6.

## 3. Resolução de deuce (40-40): 3 modos

`DeuceRule` tem três casos, escolhidos por jogo (editável depois):

- `.classicAdvantage` — vantagens clássicas: jogo só termina quando uma equipa tem 2 pontos de margem, sem limite de rondas.
- `.goldenPoint` — ponto de ouro: mal se chega a 40-40 pela primeira vez, o próximo ponto decide o jogo (sudden death imediato, sem fase de vantagem).
- `.starPoint(deuceLimit:)` — híbrido descrito pelo utilizador: joga-se vantagem normalmente nas duas primeiras vezes que o jogo chega a 40-40; à **terceira** vez que o jogo chega a 40-40 (`deuceLimit` default = 3), o próximo ponto decide o jogo sem mais vantagens.

Implementação: `GameScore.deuceCount` conta quantas vezes o jogo já esteve empatado a 40-40 (ou mais, em vantagens clássicas). `GameScoring.awardPoint` verifica, antes de aplicar o ponto, se as equipas estão empatadas e se `deuceCount` já atingiu o limiar de sudden-death definido pela regra — só nesse caso o ponto decide o jogo instantaneamente.

`MatchEngine.isGoldenPointNow` deriva-se por simulação (não duplica a lógica): simula um ponto para cada equipa via o próprio `ScoringReducer`; se **ambas** as simulações resultam em vitória imediata do jogo para quem simula, então o próximo ponto real decide o jogo seja quem for a marcar — é essa condição (e só essa) que define "sudden death ativo agora", distinguindo-a de um estado de vantagem normal (onde só uma das equipas ganharia o jogo com o próximo ponto).

## 4. HealthKit: `.tennis` como tipo de exercício

Não existe `HKWorkoutActivityType` específico para padel. Escolhido `.tennis` (padrão de movimento e modelo energético mais próximos) em vez de `.pickleball`. **Armadilha a evitar**: `.paddleSports` refere-se a remo/SUP, não é padel — nunca usar.

O tipo efetivo usado é sempre guardado em `Match.workoutActivityTypeRaw` no histórico, para a escolha poder mudar no futuro sem tornar jogos antigos inconsistentes.

## 5. WorkoutKit vs HealthKit

`WorkoutKit` (iOS 17+) serve para **propor/agendar** planos de treino estruturados (intervalos) na app Treino da Apple — não serve para **gravar** uma atividade "aberta" como um jogo de padel. A v1 usa apenas **HealthKit** (`HKWorkoutSession` + `HKLiveWorkoutBuilder`) para gravar o treino ao vivo no Watch. `WorkoutKit` fica fora de âmbito.

## 6. Sem `@Attribute(.unique)` no SwiftData

Nenhuma entidade usa `@Attribute(.unique)`. Constrangimentos unique bloqueiam uma futura ativação de CloudKit e, no iOS 17, interagem mal com upserts. A unicidade de `id` é garantida na camada de repositório (upsert por `FetchDescriptor` com predicado em `id`), não no schema.

## 7. Sem App Group na v1

iPhone e Watch são dispositivos distintos e não partilham container — a partilha de dados é sempre via WatchConnectivity. App Groups só serão necessários se/quando se adicionar um widget iOS ou complication watchOS que leia dados do host diretamente.

## 8b. Formato "Mix" (estilo Americano) e sessões

Novo `MatchFormat.mix`: joga-se jogos consecutivos (0/15/30/40, com a `DeuceRule` escolhida pelo utilizador — configurável, igual às partidas normais) **sem alvo de jogos e sem tie-break** — o placar do round fica livre (ex: "4-3", "5-5"). Implementado fazendo `MatchRules.gamesToWinSet`/`tieBreakAtGames`/`setsNeededToWin` devolverem `Int.max` para este formato, reaproveitando toda a lógica genérica de `SetScoring`/`ScoringReducer` sem qualquer `if format == .mix` espalhado pelo motor.

- **Terminar Partida**: chama `MatchEngine.endManually(at:)` — decide o vencedor da ronda pelos jogos completos (`gamesA` vs `gamesB`); **empate é um resultado válido** (ex: 4-4) quando os jogos são iguais, incluindo 0-0 se a ronda terminar sem nenhum jogo completo. Um jogo em curso mas incompleto no momento de terminar **não conta** para nenhuma das equipas (só jogos completos entram no placar do round).
- Isto obrigou a generalizar `MatchPhase.finished` para `finished(outcome: MatchOutcome, at: Date)`, onde `MatchOutcome` é `.win(Team)` ou `.draw` — as partidas normais (sets/pro-set) nunca produzem `.draw` na prática (têm sempre vencedor claro), mas o tipo já suporta o caso.
- **Terminar Sessão**: ainda não modelado em `PadelCore` (é um conceito de `PadelData`/UI, não de motor de pontuação) — cada "Terminar Partida" cria simplesmente um novo `MatchEngine` para a ronda seguinte; "Terminar Sessão" é quem decide não criar mais nenhum.

### Decisões confirmadas com o utilizador para a Fase 2 (SwiftData), a implementar quando lá chegarmos

- **Sessão** (nova entidade `Session` em `PadelData`): agrupa várias `Match` (rondas) de formato `.mix`. Guarda a duração alvo da sessão (ex: 90 min) e da ronda (ex: 15-20 min) — apenas informativos/cronómetro visível, **não** cortam a ronda automaticamente; o utilizador termina sempre manualmente.
- **Sessão de treino HealthKit contínua**: uma única `HKWorkoutSession` desde o início da sessão até "Terminar Sessão" — "Terminar Partida" NÃO pausa nem reinicia o treino, só fecha a ronda e abre a seguinte.
- **Jogadores no Mix**: a "minha equipa" (eu + nome do parceiro) usa `Player`/`MatchParticipant` normais, reutilizáveis entre sessões. Os adversários são **sempre anónimos** — `MatchParticipant` com `displayName: "Adversário 1"/"Adversário 2"` e `player: nil`, sem criar/reutilizar registos de `Player` para eles (rodam a cada ronda, não há tentativa de os identificar nem de calcular um leaderboard entre as 6+ duplas presentes — a app só regista a perspetiva de quem tem o Watch).
- **Histórico**: uma sessão Mix aparece como **uma entrada agregada** no histórico do iPhone (ex: "Mix · 7 Set · 90 min · 5 rondas"), com as rondas individuais e estatísticas agregadas da sessão dentro do ecrã de detalhe — não uma entrada por ronda.

### Correção pós-revisão: `endManually` e undo

A primeira versão de `endManually` mutava `MatchState.phase` diretamente sem passar pelo log de eventos, o que quebrava a invariante #1 (log de eventos como fonte de verdade): um `undoLastPoint()` a seguir a `endManually()` recomputava o estado só a partir de `events` (que `endManually` nunca tocou), **des-terminando** a partida e, pior, apagando silenciosamente o último ponto real registado. Corrigido com um campo privado `MatchEngine.manualEndAt: Date?`: `undoLastPoint()` agora desfaz primeiro o "terminar manualmente" (se existir) antes de começar a remover pontos reais do log — como uma pilha de undo com dois tipos de ação. `endManually` também passou a ser no-op fora do formato `.mix` (antes assumia implicitamente que só seria chamado em rondas Mix, sem impor isso).

**Limite de scope para a Fase 2 (persistência)**: `manualEndAt` vive só em memória no `MatchEngine` durante uma sessão de pontuação ativa — não é (nem precisa de ser) reconstruído a partir do log de eventos. Uma vez que um jogo termina (manual ou automaticamente) e é persistido em SwiftData, o resultado final (`Match.status`, `MatchSet.winnerTeamRaw`, `endedAt`) fica guardado diretamente nos campos da entidade — a app volta a ler esses campos como dados estáticos, não reconstrói um `MatchEngine` a partir do zero para um jogo já concluído. `MatchEngine` só precisa de ser reconstruído (via replay de `events`) para retomar uma ronda **ainda em curso**, cenário em que `endManually` nunca terá sido chamado.

## 8c. Estatísticas de análise: quebras de serviço

`MatchStatistics` ganhou `breaksOfServeA`/`breaksOfServeB` (jogos ganhos a **não** servir, por equipa) — deriva-se de `CompletedGame.servingTeam`, que já existia. Pedido do utilizador por "análise de resultado da partida" no histórico; esta é a primeira métrica de análise além de duração/pontos totais/sequência mais longa. Mais métricas (ex: % pontos ganhos ao serviço, tendência por set) ficam para quando houver pedido concreto — YAGNI.

## 8. Ambiente de desenvolvimento sem macOS local

O trabalho de implementação começou numa máquina Windows, sem Xcode/SDK watchOS/simuladores. `Packages/PadelKit` (motor de pontuação + dados) é Swift puro e compila/testa de forma independente (`swift test`), incluindo em CI (`macos-latest` no GitHub Actions) sem precisar de assinatura. Os targets de app (iOS/watchOS) só podem ser criados, compilados e validados num Mac — ver `README.md`.

## 9. Camada de UI como target do package (`PadelUI`)

As views SwiftUI vivem num segundo target do `Packages/PadelKit` (`PadelUI`), não num projeto Xcode separado. Continua a aplicar a decisão #8: o CI em `macos-latest` consegue compilar e testar tudo (`swift test` + `xcodebuild -scheme PadelUI` para os destinos iOS e watchOS simulator) antes de existir qualquer `.xcodeproj`. Quando o projeto de app for criado no Mac, os targets de app ficam finos — só `@main`, HealthKit, `WCSession` e o container SwiftData, que são precisamente as partes que não dá para validar aqui.

Regras de arquitetura para `PadelUI`:

1. Importa só `PadelCore`, `SwiftUI` e `Foundation` — nunca HealthKit, WatchConnectivity, SwiftData ou UIKit diretamente.
2. Efeitos secundários entram como closures (`onScore: (Team) -> Void`, `onUndo: () -> Void`) — sem protocolos/DI até haver uma segunda implementação real.
3. Dados do dispositivo (HealthKit, etc.) entram como structs simples (ex: `WorkoutMetrics`, todos os campos opcionais) que a app preenche mais tarde.
4. Código específico de plataforma (`#if os(...)`) só existe em `Theme/PlatformShims.swift` — todo o resto é SwiftUI cross-platform, para que o build macOS do `swift test` sirva de type-check real da UI.
5. Texto em português vive em `Formatting/Strings.swift`, não espalhado pelas views.
6. Não se adiciona API de apresentação ao `PadelCore` — `ScoreFormatter` continua a ser o único ficheiro do motor com conhecimento de apresentação; o resto (nomes de regras, durações, dots da timeline) vive em `PadelUI/Formatting`.

Ecrãs que dependem de dados que só existirão na Fase 2 (SwiftData — `Player`/`Match`/`Session`) usam structs de apresentação simples e permanentes (ex: `HistoryEntry`, `PlayerRow`), não modelos descartáveis. Os formulários "Novo Jogo" e "Nova Sessão" ficam explicitamente adiados para depois da Fase 2, para não inventar um modelo de rascunho de `Player`/`Match` que teria de ser substituído.
