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

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: revealed.map do |rx, ry|
          turbo_stream.replace("cell_#{rx}_#{ry}") do
            render partial: "games/cell", locals: { game: @game, x: rx, y: ry }
          end
        end
      end
      format.json { render json: { revealed: revealed } }
    end
  end


  private


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
