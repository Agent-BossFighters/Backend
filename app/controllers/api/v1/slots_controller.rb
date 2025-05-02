class Api::V1::SlotsController < ApplicationController
  def index
    @slots = Slot.includes(:currency, :game)

    # Filtrer par type de devise si spécifié
    if params[:currency_type].present?
      @slots = @slots.where(currencies: { name: params[:currency_type].upcase })
    end

    # Filtrer par jeu si spécifié
    if params[:game_id].present?
      @slots = @slots.where(game_id: params[:game_id])
    end

    # Filtrer les slots débloqués si demandé
    if params[:unlocked].present? && current_user
      @slots = @slots.joins(:user_slots).where(user_slots: { user_id: current_user.id })
    end

    render json: @slots.map { |slot| format_slot(slot) }
  end

  def show
    @slot = Slot.includes(:currency, :game).find(params[:id])
    render json: format_slot(@slot)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Slot not found" }, status: :not_found
  end

  def unlock
    @slot = Slot.includes(:currency, :game).find(params[:id])

    # Vérifier si le slot est déjà débloqué
    if UserSlot.exists?(user: current_user, slot: @slot)
      return render json: { error: "Slot already unlocked" }, status: :unprocessable_entity
    end

    # Traitement du slot gratuit
    if @slot.unlockCurrencyNumber.zero?
      user_slot = UserSlot.new(user: current_user, slot: @slot)
      if user_slot.save
        return render json: {
          message: "Free slot unlocked",
          slot: format_slot(@slot)
        }
      end
    end

    # Vérifications selon le type de devise
    case @slot.currency.name
    when "FLEX"
      unless current_user.isPremium?
        return render json: { error: "Premium required for FLEX slots" }, status: :forbidden
      end
    end

    # Création du UserSlot
    user_slot = UserSlot.new(user: current_user, slot: @slot)
    if user_slot.save
      render json: {
        message: "Slot unlocked successfully",
        slot: format_slot(@slot)
      }
    else
      render json: { error: user_slot.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def format_slot(slot)
    {
      id: slot.id,
      game_id: slot.game_id,
      game_name: slot.game.name,
      currency_id: slot.currency_id,
      currency_name: slot.currency.name,
      unlock_currency_number: slot.unlockCurrencyNumber,
      unlock_price: slot.unlockPrice,
      unlocked: UserSlot.exists?(user: current_user, slot: slot),
      total_cost: slot.totalCost,
      is_premium: slot.currency.name == "FLEX",
      is_free: slot.unlockCurrencyNumber.zero?
    }
  end

  def calculate_slot_metrics(slot)
    user_slots = slot.user_slots
    {
      average_profit: user_slots.joins(:matches).average("matches.profit"),
      energy_efficiency: calculate_energy_efficiency(user_slots),
      usage_count: user_slots.count
    }
  end

  def calculate_energy_efficiency(user_slots)
    matches = Match.where(slots: user_slots.pluck(:id))
    return 0 if matches.empty?
    matches.sum(:profit) / matches.sum(:energyUsed)
  end
end
