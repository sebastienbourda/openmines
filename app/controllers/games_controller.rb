class GamesController < ApplicationController
  before_action :set_game, only: [:show, :invite, :reveal, :flag]

  def show
  end


  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.seed ||= SecureRandom.hex(16)
    @game.status = :pending

    if @game.save
      # Le créateur rejoint automatiquement
      PlayerGame.create!(
        user: Current.user,
        game: @game
      )

      redirect_to @game, notice: "Game created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # POST /games/:id/invite
  def invite
    user = User.find_by(email_address: params[:email])

    if user
      PlayerGame.find_or_create_by!(user: user, game: @game)
      redirect_to @game, notice: "Player invited."
    else
      redirect_to @game, alert: "User not found."
    end
  end


  # POST /games/:id/flag
  def flag
    x, y = params.values_at(:x, :y).map(&:to_i)

    # Toggle : si déjà flaggué, on retire le drapeau
    existing = @game.actions.find_by(action_type: :flag, x: x, y: y)

    if existing
      existing.destroy
      @game.flagged_cells.delete([x, y])
      broadcast_cell(@game, x, y, flagged: false)
    else
      @game.actions.create!(user: Current.user, action_type: :flag, x: x, y: y)
      @game.flagged_cells.add([x, y])
      broadcast_cell(@game, x, y, flagged: true)
    end

    head :ok
  end

  # POST /games/:id/reveal
  def reveal
    x, y = params.values_at(:x, :y).map(&:to_i)

    # Démarrer la partie au premier clic
    @game.update!(status: :running, started_at: Time.current) if @game.pending?

    if @game.mine_at?(x, y)
      @game.update!(status: :finished, result: :lost, ended_at: Time.current)
      Action.create!(user: Current.user, game: @game, action_type: :reveal, result: :mine, x: x, y: y)

      @game.broadcast_replace_to(@game,
        target: "game_status",
        partial: "games/game_over",
        locals: { game: @game }
      )
      return head :ok
    end

    revealed = @game.reveal_cells(x, y)

    if revealed.any?
      Action.insert_all(revealed.map { |rx, ry|
        { user_id: Current.user.id, game_id: @game.id,
          action_type: Action.action_types[:reveal],
          result: Action.results[:safe],
          x: rx, y: ry,
          created_at: Time.current, updated_at: Time.current }
      })

      broadcast_revealed_cells(revealed)

      if @game.check_victory!
        @game.broadcast_replace_to(@game,
          target: "game_status",
          partial: "games/game_over",
          locals: { game: @game }
        )
      end
    end

    head :ok
  end

  private

  def broadcast_revealed_cells(revealed)
    revealed.each do |rx, ry|
      broadcast_cell(@game, rx, ry, revealed: true)
    end
  end

  def broadcast_cell(game, x, y, locals = {})
    game.broadcast_replace_later_to(
      game,
      target: "cell_#{x}_#{y}",
      partial: "games/cell",
      locals: { game: game, x: x, y: y }.merge(locals)
    )
  end

  def broadcast_game_over
    @game.broadcast_replace_to(
      @game,
      target: "game_status",
      partial: "games/game_over",
      locals: { game: @game }
    )
  end


  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(
      :name,
      :width,
      :height,
      :mine_density,
      :mode,
      :visibility
    )
  end
end
