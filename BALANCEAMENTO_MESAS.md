# Sistema de Balanceamento de Mesas

## Funcionamento

O sistema automaticamente gerencia as mesas de poker conforme jogadores entram e saem do torneio.

### Regras de Balanceamento

1. **Limite por Mesa**: Cada mesa pode ter no máximo 9 jogadores (padrão de poker)

2. **Criação de Mesas**: Quando a primeira mesa fica cheia (9 jogadores), uma nova mesa é automaticamente criada

3. **Distribuição de Jogadores**: 
   - Os jogadores são distribuídos sequencialmente
   - Exemplo com 10 jogadores:
     - Mesa 1: 9 jogadores (assentos 1-9)
     - Mesa 2: 1 jogador (assento 1)
   - Exemplo com 18 jogadores:
     - Mesa 1: 9 jogadores (assentos 1-9)
     - Mesa 2: 9 jogadores (assentos 1-9)

4. **Rebalanceamento Automático**:
   - Quando um jogador entra (seatPlayer)
   - Quando um jogador sai (unseatPlayer)
   - Quando o torneio é reiniciado (restartTournament)

### Avisos de Movimento

Quando jogadores precisam se mover entre mesas, o sistema:
1. Armazena o movimento em `pendingPlayerMoves`
2. Notifica a UI para mostrar uma tela de confirmação
3. A UI pode mostrar quem sai de qual mesa/assento e para onde vai

### Exemplo Prático

**Cenário 1 - Entrada de jogadores**
```
Inicial: 0 mesas
Entra jogador 1-9: Mesa 1 criada com 9 jogadores
Entra jogador 10: Mesa 2 criada, redistribui:
  - Mesa 1: 5 jogadores
  - Mesa 2: 5 jogadores

Entra jogador 11: Continua com 2 mesas (6-5 jogadores)
```

**Cenário 2 - Saída de jogadores**
```
Estado inicial: Mesa 1 com 6 jogadores, Mesa 2 com 4 jogadores
Jogador sai de Mesa 2: 9 jogadores no total
  - Mesa 1: 9 jogadores
  - Mesa 2: fechada (consolidada)
```

## Implementação

### Método `balanceTables()`
- Calcula o número de mesas necessárias: `requiredNumTables = ceil(numPlayers / 9)`
- Verifica se há necessidade de rebalanceamento
- Se necessário, redistributribui todos os jogadores
- Registra movimentos para exibição ao usuário

### Método `seatPlayer()`
- Coloca o jogador na mesa 1 por padrão
- Chama `balanceTables()` para redistribuir se necessário

### Método `unseatPlayer()`
- Remove o jogador
- Chama `balanceTables()` para consolidar mesas

## Status dos Movimentos

Os movimentos pendentes ficam em `TournamentController.pendingPlayerMoves` e são exibidos em uma dialog antes de serem confirmados.

Cada movimento contém:
- `player`: Jogador que se move
- `fromTable` / `fromSeat`: Posição anterior
- `toTable` / `toSeat`: Nova posição
