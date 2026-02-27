class GamesController < ApplicationController
  before_action :set_game, only: [:show, :invite, :reveal]

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

  # POST /games/:id/reveal
  def reveal
    x, y = params.values_at(:x, :y).map(&:to_i)
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
    end

    head :ok
  end


  private

  def broadcast_revealed_cells(revealed)
    revealed.each do |rx, ry|
      @game.broadcast_replace_later_to(
        @game,
        target: "cell_#{rx}_#{ry}",
        partial: "games/cell",
        locals: { game: @game, x: rx, y: ry, revealed: true  }
      )
    end
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
