module DataLab
  class SlotsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user, badge_rarity = "Common")
      @user = user
      @badge_rarity = badge_rarity || "Common"
      @badges = load_badges
    end

    def calculate
      slots = Slot.includes(:currency, :game)
      slots_costs = calculate_slots_cost(slots)

      # Calculer les valeurs constantes une seule fois
      total_flex = slots.sum(:unlockCurrencyNumber)
      total_cost = slots.sum(:unlockPrice)
      total_slots = slots.count

      # Calculer le ROI de base (constant pour toutes les raretés)
      base_roi = 340  # Valeur constante observée

      # Calculer les métriques pour chaque rareté
      rarity_metrics = Constants::BadgeConstants::RARITY_ORDER.map do |rarity|
        # Ajuster uniquement les nb_charges_roi selon la rareté
        rarity_multiplier = calculate_rarity_multiplier(rarity)

        # Créer un hash de métriques pour chaque slot
        slot_metrics = slots_costs.map do |slot_cost|
          # Calculer le multiplicateur de progression pour ce slot
          normal_part = calculate_normal_part(slot_cost[:"1. slot"])
          bonus_part = calculate_bonus_part(slot_cost[:"1. slot"])
          total_part = normal_part + bonus_part

          # Calculer le ROI ajusté pour ce slot spécifique
          slot_roi = (base_roi / rarity_multiplier).round(0)

          # Ajuster le ROI en fonction de la progression du slot
          slot_progression = total_part / 100.0  # Normaliser par rapport au slot 1
          adjusted_roi = (slot_roi * slot_progression).round(0)

          # Récupérer la valeur du coût en dollars pour ce slot
          slot_cost_value = slot_cost[:"3. flex_cost"].is_a?(String) ? 
                             slot_cost[:"3. flex_cost"].gsub('$', '').to_f : 
                             slot_cost[:"3. flex_cost"].to_f

          # Calculer le nb_tokens_roi en fonction du coût et de la valeur BFT en base
          bft_value = Constants::CurrencyConstants.currency_rates[:bft]
          tokens_roi = bft_value > 0 ? (slot_cost_value / bft_value).round(0) : 0
          
          # Récupérer directement les valeurs des constantes pour le bonus BFT
          slot_id = slot_cost[:"1. slot"]
          # Traiter spécifiquement le cas du slot 1 pour avoir 0%
          if slot_id == 1
            total_bonus_bft = 0
          else
            # Pour les autres slots, utiliser TOTAL_BONUS_BFT_PERCENT
            total_bonus_bft = Constants::SlotConstants::TOTAL_BONUS_BFT_PERCENT[slot_id] || 0
          end

          {
            "1. total_flex": slot_cost[:"2. nb_flex"],
            "2. total_cost": slot_cost[:"3. flex_cost"],
            "3. total_bonus_bft": total_bonus_bft,
            "4. nb_tokens_roi": tokens_roi,
            "5. nb_charges_roi_1.0": adjusted_roi,
            "6. nb_charges_roi_2.0": (adjusted_roi / 2.0).round(0),
            "7. nb_charges_roi_3.0": (adjusted_roi / 3.0).round(0)
          }
        end

        [rarity, slot_metrics]
      end.to_h

      {
        slots_cost: slots_costs,
        unlocked_slots_by_rarity: rarity_metrics
      }
    end

    private

    def calculate_slots_cost(slots)
      slots.map do |slot|
        values = Constants::SlotConstants::SLOT_VALUES[slot.id] || { flex: 0, cost: 0, bonus: 0 }
        {
          "1. slot": slot.id,
          "2. nb_flex": values[:flex],
          "3. flex_cost": format_currency(values[:cost]),
          "4. bonus_bft": values[:bonus],
          normalPart: calculate_normal_part(slot.id),
          bonusPart: calculate_bonus_part(slot.id)
        }
      end
    end

    def load_badges
      query = Item.includes(:type, :rarity)
                 .joins(:rarity)
                 .where(types: { name: 'Badge' })

      if @badge_rarity
        query = query.where(rarities: { name: @badge_rarity })
      end

      query.sort_by { |badge| Constants::BadgeConstants::RARITY_ORDER.index(badge.rarity.name) }
    end

    def calculate_bft_per_minute(rarity)
      return 0 unless Constants::BadgeConstants::RARITY_ORDER.include?(rarity)

      rarity_index = Constants::BadgeConstants::RARITY_ORDER.index(rarity)
      base_value = 15 # Valeur de base pour Common

      # Formule : base_value * (multiplier ^ rarity_index)
      multiplier = rarity_index <= 5 ? 2.5 : 2.0
      (base_value * (multiplier ** rarity_index)).round(0)
    end

    def calculate_max_energy(rarity)
      return 0 unless Constants::BadgeConstants::RARITY_ORDER.include?(rarity)
      Constants::BadgeConstants::RARITY_ORDER.index(rarity) + 1
    end

    def calculate_bft_value_per_charge(rarity)
      bft_per_minute = calculate_bft_per_minute(rarity)
      max_energy = calculate_max_energy(rarity)
      return 0 if bft_per_minute.nil? || max_energy.nil?

      total_bft = bft_per_minute * max_energy * 60
      (total_bft * Constants::CurrencyConstants.currency_rates[:bft]).round(2)
    end

    def calculate_recharge_cost(rarity)
      {
        flex: Constants::RechargeConstants::RECHARGE_COSTS[:flex][rarity],
        sm: Constants::RechargeConstants::RECHARGE_COSTS[:sm][rarity]
      }
    end

    def calculate_normal_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      100 * slot_id  # 100 par slot
    end

    def calculate_bonus_part(slot_id)
      return 0 unless slot_id.is_a?(Integer) && slot_id > 0
      return 0 if slot_id == 1  # Premier slot n'a pas de bonus
      200 * (2 ** (slot_id - 2))  # Progression géométrique à partir du slot 2
    end

    def calculate_total_bonus_bft(nb_slots)
      # Le bonus total est de 1 + 0.2 par slot
      1 + (nb_slots * 0.2)
    end

    def calculate_total_slots_roi(slot_total_cost, slots_count, recharge_cost, bft_value_per_charge)
      return 0 if slot_total_cost.nil? || recharge_cost.nil? ||
                 bft_value_per_charge.nil? || bft_value_per_charge.zero?

      total_cost = slot_total_cost + recharge_cost
      slots = slots_count + 1

      numerator = slot_total_cost +
                 (total_cost * slots) +
                 ((((total_cost * slots)/bft_value_per_charge) - slots) * recharge_cost)

      denominator = bft_value_per_charge * slots

      (numerator / denominator).round(0)
    end

    def calculate_rarity_multiplier(rarity)
      case rarity
      when "Common" then 1.0
      when "Uncommon" then 1.5
      when "Rare" then 2.0
      when "Epic" then 2.5
      when "Legendary" then 3.0
      when "Mythic" then 3.5
      when "Exalted" then 4.0
      when "Exotic" then 4.5
      when "Transcendent" then 5.0
      when "Unique" then 5.5
      else 1.0
      end
    end

    def calculate_unlocked_slots_with_rarity(slots, multiplier, base_roi)
      total_flex = slots.sum(:unlockCurrencyNumber)
      total_cost = slots.sum(:unlockPrice)
      nb_slots = @user.user_slots.count

      adjusted_flex = (total_flex * multiplier).round(0)
      adjusted_cost = (total_cost * multiplier).round(2)

      {
        "1. total_flex": adjusted_flex,
        "2. total_cost": format_currency(adjusted_cost),
        "3. total_bonus_bft": Constants::SlotConstants::TOTAL_BONUS_BFT_PERCENT[nb_slots] || 0,
        "4. nb_tokens_roi": (base_roi * multiplier).round(0),
        "5. nb_charges_roi_1.0": (base_roi * multiplier).round(0),
        "6. nb_charges_roi_2.0": ((base_roi * multiplier) / 2.0).round(0),
        "7. nb_charges_roi_3.0": ((base_roi * multiplier) / 3.0).round(0)
      }
    end
  end
end
