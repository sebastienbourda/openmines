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

  # Initialize sparse arrays for revealed/flagged cells
  def init_state
    @revealed_cells ||= []
    @flagged_cells  ||= []
  end

  # Deterministic mine using SHA256
  def mine_at?(x, y)
    hex = Digest::SHA256.hexdigest("#{seed}-#{x}-#{y}")
    num = hex[0..7].to_i(16)
    num % 100 < (mine_density * 100)
  end

  # Count adjacent mines for a cell
  def adjacent_mines(x, y)
    neighbors(x, y).count { |nx, ny| mine_at?(nx, ny) }
  end

  # Flood-fill reveal starting from a cell
  def reveal_cells(x, y)
    return [] if @revealed_cells.include?([x, y])

    to_reveal = [[x, y]]
    revealed = []

    until to_reveal.empty?
      cx, cy = to_reveal.pop
      next if @revealed_cells.include?([cx, cy])

      @revealed_cells << [cx, cy]
      revealed << [cx, cy]

      if adjacent_mines(cx, cy).zero? && !mine_at?(cx, cy)
        neighbors(cx, cy).each do |nx, ny|
          to_reveal << [nx, ny] unless @revealed_cells.include?([nx, ny])
        end
      end
    end

    revealed
  end

  # Return valid neighbors inside the board
  def neighbors(x, y)
    (-1..1).flat_map do |dx|
      (-1..1).map do |dy|
        nx, ny = x + dx, y + dy
        [nx, ny] if nx.between?(0, width - 1) && ny.between?(0, height - 1) && !(dx == 0 && dy == 0)
      end
    end.compact
  end
end
