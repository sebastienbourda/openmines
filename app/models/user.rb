class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :player_games
  has_many :games, through: :player_games
  has_many :actions

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
