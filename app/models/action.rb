# app/models/action.rb
class Action < ApplicationRecord
  belongs_to :user
  belongs_to :game

  enum :action_type, { reveal: 0, flag: 1 }
  enum :result,      { safe: 0, mine: 1 }
end
