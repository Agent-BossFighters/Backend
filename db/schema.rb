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

ActiveRecord::Schema[8.0].define(version: 2025_04_29_211224) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "quest_type", ["daily", "unique", "weekly", "social", "event"]

  create_table "badge_useds", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.integer "nftId"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rarity"
    t.integer "slot"
    t.index ["match_id"], name: "index_badge_useds_on_match_id"
    t.index ["nftId"], name: "index_badge_useds_on_nftId"
  end

  create_table "contract_level_costs", force: :cascade do |t|
    t.integer "level", null: false
    t.integer "flex_cost", null: false
    t.integer "sponsor_mark_cost", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level"], name: "index_contract_level_costs_on_level", unique: true
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.boolean "onChain"
    t.float "price"
    t.bigint "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_currencies_on_game_id"
  end

  create_table "currency_packs", force: :cascade do |t|
    t.bigint "currency_id", null: false
    t.integer "currencyNumber"
    t.float "price"
    t.float "unitPrice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_currency_packs_on_currency_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_craftings", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.integer "unit_to_craft"
    t.integer "flex_craft"
    t.integer "sponsor_mark_craft"
    t.integer "nb_lower_badge_to_craft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "craft_tokens"
    t.integer "sponsor_marks_reward"
    t.integer "craft_time"
    t.integer "max_level"
    t.index ["item_id"], name: "index_item_craftings_on_item_id"
  end

  create_table "item_farmings", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.float "efficiency"
    t.float "ratio"
    t.integer "in_game_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_farmings_on_item_id"
  end

  create_table "item_recharges", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.integer "max_energy_recharge"
    t.integer "time_to_charge"
    t.integer "flex_charge"
    t.integer "sponsor_mark_charge"
    t.float "unit_charge_cost"
    t.float "max_charge_cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_recharges_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "rarity"
    t.string "type"
    t.string "name"
    t.float "efficiency"
    t.integer "nfts"
    t.integer "supply"
    t.float "floorPrice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "type_id"
    t.bigint "rarity_id"
    t.index ["rarity_id"], name: "index_items_on_rarity_id"
    t.index ["type_id"], name: "index_items_on_type_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "build"
    t.datetime "date"
    t.string "map"
    t.integer "totalFee"
    t.float "feeCost"
    t.integer "slots"
    t.float "luckrate"
    t.integer "time"
    t.integer "energyUsed"
    t.float "energyCost"
    t.integer "totalToken"
    t.float "tokenValue"
    t.integer "totalPremiumCurrency"
    t.float "premiumCurrencyValue"
    t.float "profit"
    t.float "bonusMultiplier"
    t.float "perksMultiplier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "result"
    t.index ["user_id"], name: "index_matches_on_user_id"
  end

  create_table "nfts", force: :cascade do |t|
    t.integer "issueId"
    t.integer "itemId"
    t.string "owner"
    t.float "purchasePrice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["itemId"], name: "index_nfts_on_itemId"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name"
    t.string "provider"
    t.boolean "is_active", default: true
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider"], name: "index_payment_methods_on_provider", unique: true
  end

  create_table "player_cycles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "playerCycleType"
    t.string "cycleName"
    t.integer "nbBadge"
    t.string "minimumBadgeRarity"
    t.datetime "startDate"
    t.datetime "endDate"
    t.integer "nbDateRepeat"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_player_cycles_on_user_id"
  end

  create_table "quests", force: :cascade do |t|
    t.string "quest_id", null: false
    t.string "title", limit: 100, null: false
    t.text "description"
    t.enum "quest_type", null: false, enum_type: "quest_type"
    t.integer "xp_reward", default: 0, null: false
    t.string "icon_url"
    t.integer "progress_required", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target_tweet_id"
    t.string "target_tweet_url"
    t.string "validation_type", default: "retweet"
    t.string "zealy_quest_id"
    t.index ["quest_id"], name: "index_quests_on_quest_id", unique: true
  end

  create_table "rarities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "round_number", null: false
    t.decimal "team_a_damage", precision: 10, scale: 2, default: "0.0"
    t.decimal "team_b_damage", precision: 10, scale: 2, default: "0.0"
    t.decimal "team_a_survival_time", precision: 10, scale: 2, default: "0.0"
    t.decimal "team_b_survival_time", precision: 10, scale: 2, default: "0.0"
    t.integer "team_a_points", default: 0
    t.integer "team_b_points", default: 0
    t.bigint "match_id", null: false
    t.bigint "boss_a_id"
    t.bigint "boss_b_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tournament_match_id", null: false
    t.index ["boss_a_id"], name: "index_rounds_on_boss_a_id"
    t.index ["boss_b_id"], name: "index_rounds_on_boss_b_id"
    t.index ["match_id", "round_number"], name: "index_rounds_on_match_id_and_round_number", unique: true
    t.index ["match_id"], name: "index_rounds_on_match_id"
    t.index ["tournament_match_id"], name: "index_rounds_on_tournament_match_id"
  end

  create_table "slots", force: :cascade do |t|
    t.bigint "currency_id", null: false
    t.bigint "game_id", null: false
    t.integer "unlockCurrencyNumber"
    t.float "unlockPrice"
    t.boolean "unlocked"
    t.float "totalCost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "bonus_multiplier"
    t.float "bonus_bft_percent"
    t.integer "base_bonus_part"
    t.integer "flex_value"
    t.float "cost_value"
    t.float "bonus_value"
    t.index ["currency_id"], name: "index_slots_on_currency_id"
    t.index ["game_id"], name: "index_slots_on_game_id"
  end

  create_table "social_quest_submissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "quest_id", null: false
    t.string "submitted_tweet_url", null: false
    t.boolean "valid", default: false
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "quest_id"], name: "index_social_quest_submissions_on_user_id_and_quest_id", unique: true
    t.index ["user_id"], name: "index_social_quest_submissions_on_user_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.integer "slot_number", null: false
    t.boolean "is_boss_eligible", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "slot_number"], name: "index_team_members_on_team_id_and_slot_number", unique: true
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "invitation_code"
    t.decimal "total_damage", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_survival_time", precision: 10, scale: 2, default: "0.0"
    t.bigint "tournament_id", null: false
    t.bigint "captain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_empty", default: false
    t.index ["captain_id"], name: "index_teams_on_captain_id"
    t.index ["invitation_code"], name: "index_teams_on_invitation_code", unique: true, where: "(invitation_code IS NOT NULL)"
    t.index ["tournament_id", "name"], name: "index_teams_on_tournament_id_and_name", unique: true
    t.index ["tournament_id"], name: "index_teams_on_tournament_id"
  end

  create_table "tournament_admins", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.bigint "user_id", null: false
    t.boolean "is_creator", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "is_creator"], name: "index_tournament_admins_on_tournament_id_and_is_creator"
    t.index ["tournament_id", "user_id"], name: "index_tournament_admins_on_tournament_id_and_user_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_admins_on_tournament_id"
    t.index ["user_id"], name: "index_tournament_admins_on_user_id"
  end

  create_table "tournament_matches", force: :cascade do |t|
    t.integer "match_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "round_number", null: false
    t.datetime "scheduled_time"
    t.integer "team_a_points", default: 0
    t.integer "team_b_points", default: 0
    t.bigint "tournament_id", null: false
    t.bigint "team_a_id", null: false
    t.bigint "team_b_id"
    t.bigint "boss_id", null: false
    t.bigint "winner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["boss_id"], name: "index_tournament_matches_on_boss_id"
    t.index ["status"], name: "index_tournament_matches_on_status"
    t.index ["team_a_id"], name: "index_tournament_matches_on_team_a_id"
    t.index ["team_b_id"], name: "index_tournament_matches_on_team_b_id"
    t.index ["tournament_id", "round_number"], name: "index_tournament_matches_on_tournament_id_and_round_number"
    t.index ["tournament_id"], name: "index_tournament_matches_on_tournament_id"
    t.index ["winner_id"], name: "index_tournament_matches_on_winner_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name", null: false
    t.integer "tournament_type", null: false
    t.integer "status", default: 0, null: false
    t.text "rules"
    t.string "entry_code"
    t.integer "agent_level_required", default: 0, null: false
    t.integer "players_per_team", null: false
    t.integer "min_players_per_team"
    t.integer "max_teams", null: false
    t.boolean "is_premium_only", default: false, null: false
    t.bigint "creator_id", null: false
    t.bigint "boss_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rounds", default: 1, null: false
    t.boolean "auto_create_teams", default: false
    t.index ["boss_id"], name: "index_tournaments_on_boss_id"
    t.index ["creator_id"], name: "index_tournaments_on_creator_id"
    t.index ["entry_code"], name: "index_tournaments_on_entry_code", unique: true, where: "(entry_code IS NOT NULL)"
    t.index ["status"], name: "index_tournaments_on_status"
    t.index ["tournament_type"], name: "index_tournaments_on_tournament_type"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "payment_method_id", null: false
    t.decimal "amount", precision: 18, scale: 8
    t.string "currency"
    t.string "status"
    t.string "external_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_transactions_on_external_id"
    t.index ["payment_method_id"], name: "index_transactions_on_payment_method_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_builds", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "buildName"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "bftBonus", default: 0.0
    t.index ["user_id"], name: "index_user_builds_on_user_id"
  end

  create_table "user_quest_completions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "quest_id", null: false
    t.date "completion_date"
    t.integer "progress", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completable", default: false, null: false
    t.index ["completable"], name: "index_user_quest_completions_on_completable"
    t.index ["user_id", "quest_id", "completion_date"], name: "idx_user_quests_unique_completion", unique: true
    t.index ["user_id"], name: "index_user_quest_completions_on_user_id"
  end

  create_table "user_recharges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "discountTime"
    t.integer "discountNumber"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_recharges_on_user_id"
  end

  create_table "user_slots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "slot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slot_id"], name: "index_user_slots_on_slot_id"
    t.index ["user_id"], name: "index_user_slots_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "isPremium"
    t.integer "level"
    t.float "experience"
    t.string "assetType"
    t.string "asset"
    t.integer "slotUnlockedId"
    t.string "maxRarity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.boolean "is_admin", default: false
    t.integer "flex_pack", default: 1
    t.string "session_token"
    t.string "current_jti"
    t.string "zealy_user_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_admin"], name: "index_users_on_is_admin"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["session_token"], name: "index_users_on_session_token"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["zealy_user_id"], name: "index_users_on_zealy_user_id", unique: true
  end

  add_foreign_key "badge_useds", "matches"
  add_foreign_key "badge_useds", "nfts", column: "nftId"
  add_foreign_key "currencies", "games"
  add_foreign_key "currency_packs", "currencies"
  add_foreign_key "item_craftings", "items"
  add_foreign_key "item_farmings", "items"
  add_foreign_key "item_recharges", "items"
  add_foreign_key "items", "rarities"
  add_foreign_key "items", "types"
  add_foreign_key "matches", "users"
  add_foreign_key "nfts", "items", column: "itemId"
  add_foreign_key "player_cycles", "users"
  add_foreign_key "rounds", "tournament_matches"
  add_foreign_key "rounds", "tournament_matches", column: "match_id"
  add_foreign_key "rounds", "users", column: "boss_a_id"
  add_foreign_key "rounds", "users", column: "boss_b_id"
  add_foreign_key "slots", "currencies"
  add_foreign_key "slots", "games"
  add_foreign_key "social_quest_submissions", "quests", primary_key: "quest_id"
  add_foreign_key "social_quest_submissions", "users"
  add_foreign_key "team_members", "teams"
  add_foreign_key "team_members", "users"
  add_foreign_key "teams", "tournaments"
  add_foreign_key "teams", "users", column: "captain_id"
  add_foreign_key "tournament_admins", "tournaments"
  add_foreign_key "tournament_admins", "users"
  add_foreign_key "tournament_matches", "teams", column: "team_a_id"
  add_foreign_key "tournament_matches", "teams", column: "team_b_id"
  add_foreign_key "tournament_matches", "teams", column: "winner_id"
  add_foreign_key "tournament_matches", "tournaments"
  add_foreign_key "tournament_matches", "users", column: "boss_id"
  add_foreign_key "tournaments", "users", column: "boss_id"
  add_foreign_key "tournaments", "users", column: "creator_id"
  add_foreign_key "transactions", "payment_methods"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_builds", "users"
  add_foreign_key "user_quest_completions", "quests", primary_key: "quest_id"
  add_foreign_key "user_quest_completions", "users"
  add_foreign_key "user_recharges", "users"
  add_foreign_key "user_slots", "slots"
  add_foreign_key "user_slots", "users"
end
