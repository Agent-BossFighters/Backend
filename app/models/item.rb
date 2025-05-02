class Item < ApplicationRecord
  self.inheritance_column = nil  # Désactive STI

  belongs_to :type
  belongs_to :rarity
  has_one :item_farming
  has_one :item_crafting
  has_one :item_recharge
  has_many :nfts, foreign_key: :itemId

  # Scope pour inclure les associations par défaut
  default_scope { includes(:rarity, :type) }

  # Méthodes spécifiques pour les contrats de showrunner
  def showrunner?
    type.name == "Showrunner"
  end

  def contract_requirements
    return unless showrunner?
    {
      required_matches: item_farming&.in_game_time || 10,
      min_win_rate: efficiency || 50,
      reward_amount: floorPrice || 100
    }
  end

  def calculate_contract_progress(user)
    return unless showrunner?

    matches = user.matches
                 .where("created_at >= ?", 24.hours.ago)
                 .where(game_id: game_id)

    total_matches = matches.count
    won_matches = matches.where(result: "win").count
    win_rate = total_matches > 0 ? (won_matches.to_f / total_matches * 100).round(2) : 0

    {
      matches_played: total_matches,
      matches_required: contract_requirements[:required_matches],
      current_win_rate: win_rate,
      required_win_rate: contract_requirements[:min_win_rate],
      completion_percentage: calculate_completion_percentage(total_matches, win_rate)
    }
  end

  # Métriques de base
  def max_energy
    item_recharge&.max_energy_recharge
  end

  def time_to_charge
    item_recharge&.time_to_charge
  end

  def ratio
    item_farming&.ratio || 1.0
  end

  # Métriques calculées pour les badges
  def sbft_per_minute
    (efficiency * ratio).round(2)
  end

  def sbft_per_charge
    (sbft_per_minute * max_energy).round(2)
  end

  def sbft_value_per_charge
    (sbft_per_charge * floorPrice).round(2)
  end

  # Métriques calculées pour les showrunner contracts
  def required_matches
    item_farming&.in_game_time
  end

  def required_win_rate
    efficiency
  end

  def reward_amount
    floorPrice
  end

  private

  def calculate_completion_percentage(total_matches, win_rate)
    return 0 if total_matches == 0

    requirements = contract_requirements
    matches_percentage = [ total_matches.to_f / requirements[:required_matches] * 100, 100 ].min
    win_rate_percentage = [ win_rate / requirements[:min_win_rate] * 100, 100 ].min

    [ (matches_percentage + win_rate_percentage) / 2, 100 ].min
  end
end
