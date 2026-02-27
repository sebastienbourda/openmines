class CreatePlayerGames < ActiveRecord::Migration[8.0]
  def change
    create_table :player_games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :deaths
      t.integer :revealed_cells_count
      t.integer :flags_count

      t.timestamps
    end
  end
end
