class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :name
      t.integer :width
      t.integer :height
      t.decimal :mine_density, precision: 5, scale: 4, default: 0.15, null: false
      t.string :seed
      t.integer :status
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
