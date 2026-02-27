class AddIndexToActionsGameActionType < ActiveRecord::Migration[8.0]
  def change
    add_index :actions, [:game_id, :action_type]
  end
end
