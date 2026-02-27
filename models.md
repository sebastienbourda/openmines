# OpenMines – Core Models Reference

Architecture reference for the deterministic multiplayer Minesweeper engine.

---

## 1. Game

Represents a single game instance.

### Attributes

- id
- name
- width (integer)
- height (integer)
- mine_density (float/decimal, e.g. 0.15)
- seed (string) – deterministic generation base
- status (enum: pending, active, finished)
- started_at (datetime)
- ended_at (datetime)

### Responsibilities

- Defines board dimensions
- Stores deterministic seed
- Defines global rules
- Does NOT store mines physically

### Relations

- has_many :cell_states
- has_many :player_games
- has_many :players, through: :player_games
- has_many :actions

---

## 2. User (Player)

Represents a user.

### Attributes

- id
- username
- score
- created_at

### Relations

- has_many :player_games
- has_many :games, through: :player_games
- has_many :actions

---

## 3. PlayerGame (Join Model)

Connects players to games (multiplayer support).

### Attributes

- player_id
- game_id
- deaths (integer)
- revealed_cells_count (integer)
- flags_count (integer)

### Purpose

- Track player statistics per game
- Support multiplayer sessions

---

## 4. CellState

Stores only modified cells (no full grid storage).

### Attributes

- id
- game_id
- x (integer)
- y (integer)
- revealed (boolean)
- flagged (boolean)
- revealed_by_player_id
- revealed_at (datetime)

### Index Recommendation

Unique index on:

(game_id, x, y)

### Responsibilities

- Stores visible state
- Prevents double reveal
- Supports concurrency control

---

## 5. Action (Optional but Recommended)

Stores action history for replay, audit and debugging.

### Attributes

- id
- player_id
- game_id
- action_type (enum: reveal, flag)
- x
- y
- result (mine, safe, number)
- created_at

### Purpose

- Anti-cheat
- Replay system
- Statistics
- Concurrency debugging

---

# Services (Not ActiveRecord Models)

---

## 6. MineEngine (Deterministic Generator)

Generates mines deterministically using:

- game.seed
- x
- y

Example logic:

```ruby
def mine?(x, y)
  hash = SHA256("#{seed}-#{x}-#{y}")
  normalized = hash.to_i(16) % 1_000_000 / 1_000_000.0
  normalized < mine_density
end
