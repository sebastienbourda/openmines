class AddModeAndVisibilityToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :mode, :integer, default: 0, null: false
    add_column :games, :visibility, :integer, default: 0, null: false
  end
end
