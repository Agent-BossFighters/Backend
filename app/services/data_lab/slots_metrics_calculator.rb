module DataLab
  class SlotsMetricsCalculator
    include Constants::Utils
    include Constants::Calculator

    def initialize(user, badge_rarity = "Common")
      @user = user
      @badge_rarity = badge_rarity || "Common"
      @badges = load_badges
      @user_rates = Constants::CurrencyConstants.user_currency_rates(@user)
      @bft_value = Constants::CurrencyConstants.currency_rates[:bft]
      @badge_calculator = DataLab::BadgesMetricsCalculator.new(user)
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

          # Récupérer directement les valeurs des constantes pour le bonus BFT
          slot_id = slot_cost[:"1. slot"]

          
          # Calculer le 1.total_flex
          cumulative_flex = 0
          slots_costs.each do |s|
            if s[:"1. slot"] <= slot_id
              cumulative_flex += s[:"2. nb_flex"].to_i
            end
          end
          total_flex = cumulative_flex
          
          # Calculer le 2.total_cost basé sur le total_flex
          flex_value = @user_rates[:flex]
          total_cost = format_currency(total_flex * flex_value)
          # Puisonvertir total_cost en nombre en retirant le symbole $ et en convertissant en float
          if total_cost.is_a?(String)
            numeric_cost = total_cost.gsub('$', '').to_f
          else
            numeric_cost = total_cost.to_f
          end
          
          # Pour le 3. total_bonus_bft, utiliser TOTAL_BONUS_BFT_PERCENT
          total_bonus_bft = Constants::SlotConstants::TOTAL_BONUS_BFT_PERCENT[slot_id] || 0

          # Calculer le 4. nb_tokens_roi en fonction du coût et de la valeur BFT en base
          tokens_roi = @bft_value > 0 ? (numeric_cost / @bft_value).round(0) : 0
          
          # Calculer le 5. nb_charges_roi_1.0
          badge_details = @badge_calculator.calculate[:badges_details]
          badge_detail = badge_details.find { |m| m[:"1. rarity"] == rarity }
          bft_per_max_charge = badge_detail && badge_detail[:"6. bft_per_max_charge"].to_f || 0
          
          if tokens_roi  < 1
            adjusted_roi = 0
          else 
            adjusted_roi = (tokens_roi / (bft_per_max_charge * slot_id * (1+(total_bonus_bft / 100.0)))).round(2)
          end

          {
            "1. total_flex": total_flex,
            "2. total_cost": total_cost,
            "3. total_bonus_bft": total_bonus_bft,
            "4. nb_tokens_roi": tokens_roi,
            "5. nb_charges_roi_1.0": adjusted_roi,
            "6. nb_charges_roi_2.0": (adjusted_roi / 2.0).round(2),
            "7. nb_charges_roi_3.0": (adjusted_roi / 3.0).round(2)
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

        flex_amount = values[:flex] * @user_rates[:flex]

        {
          "1. slot": slot.id,
          "2. nb_flex": values[:flex],
          "3. flex_cost": format_currency(flex_amount),
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
