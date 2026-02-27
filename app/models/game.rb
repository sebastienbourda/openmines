# app/models/game.rb
class Game < ApplicationRecord
  require 'digest'

  has_many :actions, dependent: :destroy
  has_many :player_games, dependent: :destroy
  has_many :users, through: :player_games

  attr_accessor :revealed_cells, :flagged_cells

  after_initialize :init_state

  enum :status, { pending: 0, running: 1, finished: 2 }
  enum :result, { default: 0, won: 1, lost: 2 }
  enum :mode, { solo: 0, multiplayer: 1 }
  enum :visibility, { private_game: 0, public_game: 1 }

  scope :for_user, ->(user) {
    left_joins(:player_games)
      .where(player_games: { user_id: user.id })
      .or(where(visibility: :public_game))
      .distinct
  }

  validates :width, :height, presence: true
  validates :mine_density, numericality: { greater_than: 0, less_than: 1 }

  # Reconstituée depuis la table actions si le game est persisté
  def init_state
    @mine_cache = {}

    if persisted?
      rows = actions.pluck(:action_type, :x, :y)
      # action_type: 0 = reveal, 1 = flag
      @revealed_cells = Set.new(rows.filter_map { |t, x, y| [x, y] if t == 0 })
      @flagged_cells  = Set.new(rows.filter_map { |t, x, y| [x, y] if t == 1 })
    else
      @revealed_cells = Set.new
      @flagged_cells  = Set.new
    end
  end

  # Déterministe via SHA256, avec cache mémoire
  def mine_at?(x, y)
    @mine_cache[[x, y]] ||= begin
      hex = Digest::SHA256.hexdigest("#{seed}-#{x}-#{y}")
      hex[0..7].to_i(16) % 100 < (mine_density * 100)
    end
  end

  def adjacent_mines(x, y)
    neighbors(x, y).count { |nx, ny| mine_at?(nx, ny) }
  end

  def reveal_cells(x, y)
    return [] if @revealed_cells.include?([x, y])

    to_reveal = [[x, y]]
    revealed  = []

    until to_reveal.empty?
      cx, cy = to_reveal.pop
      next if @revealed_cells.include?([cx, cy])

      @revealed_cells.add([cx, cy])
      revealed << [cx, cy]

      if adjacent_mines(cx, cy).zero? && !mine_at?(cx, cy)
        neighbors(cx, cy).each do |nx, ny|
          to_reveal << [nx, ny] unless @revealed_cells.include?([nx, ny])
        end
      end
    end

    revealed
  end

  def neighbors(x, y)
    (-1..1).flat_map do |dx|
      (-1..1).map do |dy|
        nx, ny = x + dx, y + dy
        [nx, ny] if nx.between?(0, width - 1) && ny.between?(0, height - 1) && !(dx == 0 && dy == 0)
      end
    end.compact
  end

  # Retourne true si le coup touche une mine, et termine la partie
  def hit_mine!(user)
    return false unless mine_at_pending_reveal?
    update!(status: :finished, result: :lost, ended_at: Time.current)
    true
  end

  # Vérifie si toutes les cases sûres sont révélées → victoire
  def check_victory!
    safe_cells = (width * height) - total_mines
    if @revealed_cells.size >= safe_cells
      update!(status: :finished, result: :won, ended_at: Time.current)
      true
    else
      false
    end
  end

  def total_mines
    @total_mines ||= (width * height * mine_density).floor
  end
end
