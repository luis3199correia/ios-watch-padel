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

## 8. Ambiente de desenvolvimento sem macOS local

O trabalho de implementação começou numa máquina Windows, sem Xcode/SDK watchOS/simuladores. `Packages/PadelKit` (motor de pontuação + dados) é Swift puro e compila/testa de forma independente (`swift test`), incluindo em CI (`macos-latest` no GitHub Actions) sem precisar de assinatura. Os targets de app (iOS/watchOS) só podem ser criados, compilados e validados num Mac — ver `README.md`.
