class CreateActions < ActiveRecord::Migration[8.0]
  def change
    create_table :actions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :action_type
      t.integer :x
      t.integer :y
      t.integer :result

      t.timestamps
    end
  end
end
