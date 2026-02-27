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

    # 1. La cellule est une mine → game over immédiat
    if @game.mine_at?(x, y)
      @game.update!(status: :finished, result: :lost, ended_at: Time.current)
      Action.create!(
        user: Current.user, game: @game,
        action_type: :reveal, x: x, y: y, result: :mine
      )

      # Broadcaster le game over à tous les joueurs
      broadcast_game_over

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("game_status", partial: "games/game_over", locals: { game: @game }) }
        format.json { render json: { status: :lost } }
      end
      return
    end

    # 2. Case safe → flood-fill
    revealed = @game.reveal_cells(x, y)

    if revealed.any?
      Action.insert_all(revealed.map { |rx, ry|
        { user_id: Current.user.id, game_id: @game.id,
          action_type: Action.action_types[:reveal],
          result: Action.results[:safe],
          x: rx, y: ry,
          created_at: Time.current, updated_at: Time.current }
      })

      # Broadcaster les cellules révélées à tous les autres joueurs
      broadcast_revealed_cells(revealed)

      # 3. Vérifier la victoire
      if @game.check_victory!
        broadcast_game_over
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: revealed.map { |rx, ry|
          turbo_stream.replace("cell_#{rx}_#{ry}") do
            render partial: "games/cell", locals: { game: @game, x: rx, y: ry }
          end
        }
      end
      format.json { render json: { revealed: revealed } }
    end
  end


  private

  def broadcast_revealed_cells(revealed)
    turbo_streams = revealed.map do |rx, ry|
      turbo_stream.replace("cell_#{rx}_#{ry}") do
        render_to_string partial: "games/cell", locals: { game: @game, x: rx, y: ry }
      end
    end

    # broadcast_to envoie à tous les abonnés du channel @game
    # y compris le joueur courant — on le gérera côté vue avec un flag ou on accepte le double update (idempotent)
    Turbo::StreamsChannel.broadcast_action_to(
      @game,
      action: :replace,
      targets: revealed.map { |rx, ry| "cell_#{rx}_#{ry}" },
      # ...
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
