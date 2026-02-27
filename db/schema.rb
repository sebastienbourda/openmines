# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_22_200046) do
  create_table "actions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "game_id", null: false
    t.integer "action_type"
    t.integer "x"
    t.integer "y"
    t.integer "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_actions_on_game_id"
    t.index ["user_id"], name: "index_actions_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name"
    t.integer "width"
    t.integer "height"
    t.decimal "mine_density", precision: 5, scale: 4, default: "0.15", null: false
    t.string "seed"
    t.integer "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mode", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.integer "result"
  end

  create_table "player_games", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "game_id", null: false
    t.integer "deaths"
    t.integer "revealed_cells_count"
    t.integer "flags_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_player_games_on_game_id"
    t.index ["user_id"], name: "index_player_games_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "actions", "games"
  add_foreign_key "actions", "users"
  add_foreign_key "player_games", "games"
  add_foreign_key "player_games", "users"
  add_foreign_key "sessions", "users"
end
