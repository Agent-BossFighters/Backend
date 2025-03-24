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

      # Cache pour les slots et leurs données associées
      @slots_cache = nil
      @slots_costs_cache = nil
      @currency_rates_cache = {
        'FLEX' => Currency.find_by(name: 'FLEX')&.price || 0,
        'Sponsor Marks' => Currency.find_by(name: 'Sponsor Marks')&.price || 0,
        'BFT' => Currency.find_by(name: '$BFT')&.price || 0
      }
    end

    def calculate
      # Charger et mettre en cache les slots avec leurs associations
      @slots_cache ||= Slot.includes(:currency, :game).to_a
      @slots_costs_cache ||= calculate_slots_cost(@slots_cache)

      # Calculer les valeurs constantes une seule fois
      total_flex = @slots_cache.sum(&:unlockCurrencyNumber)
      total_cost = @slots_cache.sum(&:unlockPrice)
      total_slots = @slots_cache.count

      # Calculer le ROI de base (constant pour toutes les raretés)
      base_roi = 340  # Valeur constante observée

      # Calculer les métriques pour chaque rareté
      rarity_metrics = Rarity.order(:id).map do |rarity|
        [rarity.name, calculate_rarity_metrics(rarity, @slots_costs_cache)]
      end.to_h

      {
        slots_cost: @slots_costs_cache,
        unlocked_slots_by_rarity: rarity_metrics
      }
    end

    private

    def calculate_rarity_metrics(rarity, slots_costs)
      # Ajuster uniquement les nb_charges_roi selon la rareté
      rarity_multiplier = calculate_rarity_multiplier(rarity.name)

      # Créer un hash de métriques pour chaque slot
      slots_costs.map do |slot_cost|
        calculate_slot_metrics(slot_cost, rarity_multiplier)
      end
    end

    def calculate_slot_metrics(slot_cost, rarity_multiplier)
      slot_id = slot_cost[:"1. slot"]

      # Calculer le multiplicateur de progression pour ce slot
      normal_part = calculate_normal_part(slot_id)
      bonus_part = calculate_bonus_part(slot_id)
      total_part = normal_part + bonus_part

      # Calculer le total_flex cumulatif
      cumulative_flex = calculate_cumulative_flex(slot_id)

      # Calculer le coût total
      flex_value = @user_rates[:flex]
      total_cost = format_currency(cumulative_flex * flex_value)
      numeric_cost = total_cost.is_a?(String) ? total_cost.gsub('$', '').to_f : total_cost.to_f

      # Récupérer le bonus BFT du slot
      slot = @slots_cache.find { |s| s.id == slot_id }
      total_bonus_bft = slot&.bonus_bft_percent || 0

      # Calculer les tokens ROI
      tokens_roi = calculate_tokens_roi(numeric_cost)

      # Calculer le ROI ajusté
      adjusted_roi = calculate_adjusted_roi(tokens_roi, slot_id, total_bonus_bft)

      {
        "1. total_flex": cumulative_flex,
        "2. total_cost": total_cost,
        "3. total_bonus_bft": total_bonus_bft,
        "4. nb_tokens_roi": tokens_roi,
        "5. nb_charges_roi_1.0": adjusted_roi,
        "6. nb_charges_roi_2.0": (adjusted_roi / 2.0).round(2),
        "7. nb_charges_roi_3.0": (adjusted_roi / 3.0).round(2)
      }
    end

    def calculate_cumulative_flex(slot_id)
      @slots_costs_cache.select { |s| s[:"1. slot"] <= slot_id }
                       .sum { |s| s[:"2. nb_flex"].to_i }
    end

    def calculate_tokens_roi(numeric_cost)
      @bft_value > 0 ? (numeric_cost / @bft_value).round(0) : 0
    end

    def calculate_adjusted_roi(tokens_roi, slot_id, total_bonus_bft)
      return 0 if tokens_roi < 1

      badge_details = @badge_calculator.calculate[:badges_details]
      badge_detail = badge_details.find { |m| m[:"1. rarity"] == @badge_rarity }
      bft_per_max_charge = badge_detail && badge_detail[:"6. bft_per_max_charge"].to_f || 0

      (tokens_roi / (bft_per_max_charge * slot_id * (1 + (total_bonus_bft / 100.0)))).round(2)
    end

    def calculate_slots_cost(slots)
      slots.map do |slot|
        flex_amount = slot.unlockCurrencyNumber * @user_rates[:flex]

        {
          "1. slot": slot.id,
          "2. nb_flex": slot.unlockCurrencyNumber,
          "3. flex_cost": format_currency(flex_amount),
          "4. bonus_bft": slot.bonus_value,
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

      query.order('rarities.id ASC')
    end

    def calculate_bft_per_minute(rarity)
      rarity_record = Rarity.find_by(name: rarity)
      return 0 unless rarity_record

      rarity_index = rarity_record.id - 1 # Soustrait 1 car les IDs commencent à 1
      base_value = 15 # Valeur de base pour Common

      # Formule : base_value * (multiplier ^ rarity_index)
      multiplier = rarity_index <= 5 ? 2.5 : 2.0
      (base_value * (multiplier ** rarity_index)).round(0)
    end

    def calculate_max_energy(rarity)
      rarity_record = Rarity.find_by(name: rarity)
      return 0 unless rarity_record
      rarity_record.id # L'ID correspond à l'énergie max
    end

    def calculate_bft_value_per_charge(rarity)
      bft_per_minute = calculate_bft_per_minute(rarity)
      max_energy = calculate_max_energy(rarity)
      return 0 if bft_per_minute.nil? || max_energy.nil?

      total_bft = bft_per_minute * max_energy * 60
      (total_bft * Constants::CurrencyConstants.currency_rates[:bft]).round(2)
    end

    def calculate_recharge_cost(rarity)
      item = Item.includes(:item_recharge)
                .joins(:rarity)
                .where(rarities: { name: rarity }, types: { name: 'Badge' })
                .first

      return { flex: 0, sm: 0 } unless item&.item_recharge

      {
        flex: item.item_recharge.flex_charge || 0,
        sm: item.item_recharge.sponsor_mark_charge || 0
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

      slot = Slot.find_by(id: nb_slots)
      total_bonus_bft = slot&.bonus_bft_percent || 0

      {
        "1. total_flex": adjusted_flex,
        "2. total_cost": format_currency(adjusted_cost),
        "3. total_bonus_bft": total_bonus_bft,
        "4. nb_tokens_roi": (base_roi * multiplier).round(0),
        "5. nb_charges_roi_1.0": (base_roi * multiplier).round(0),
        "6. nb_charges_roi_2.0": ((base_roi * multiplier) / 2.0).round(0),
        "7. nb_charges_roi_3.0": ((base_roi * multiplier) / 3.0).round(0)
      }
    end
  end
end
