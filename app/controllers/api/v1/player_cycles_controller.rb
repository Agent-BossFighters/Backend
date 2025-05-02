class Api::V1::PlayerCyclesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_cycle, only: [ :show, :update, :destroy ]

  def index
    @cycles = current_user.player_cycles
    render json: {
      cycles: @cycles.map { |cycle| cycle_json(cycle) },
      total_count: @cycles.count
    }
  end

  def show
    if @cycle
      render json: {
        cycle: cycle_json(@cycle),
        metrics: cycle_metrics(@cycle)
      }
    else
      render json: {
        error: "Cycle not found",
        message: "No cycle found with ID #{params[:id]} for current user",
        user_id: current_user.id,
        requested_cycle_id: params[:id]
      }, status: :not_found
    end
  end

  def create
    @cycle = current_user.player_cycles.new(cycle_params)

    if @cycle.save
      render json: { cycle: cycle_json(@cycle) }, status: :created
    else
      render json: { error: @cycle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @cycle.update(cycle_params)
      render json: { cycle: cycle_json(@cycle) }
    else
      render json: { error: @cycle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @cycle.destroy
    render json: { message: "Cycle successfully deleted" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Cycle not found or not accessible" }, status: :not_found
  end

  private

  def set_cycle
    @cycle = current_user.player_cycles.find_by(id: params[:id])
  end

  def cycle_params
    params.require(:player_cycle).permit(
      :playerCycleType,
      :cycleName,
      :nbBadge,
      :minimumBadgeRarity,
      :startDate,
      :endDate,
      :nbDateRepeat
    )
  end

  def cycle_json(cycle)
    {
      id: cycle.id,
      cycle_type: cycle.playerCycleType,
      name: cycle.cycleName,
      badges_count: cycle.nbBadge,
      minimum_rarity: cycle.minimumBadgeRarity,
      start_date: cycle.startDate,
      end_date: cycle.endDate,
      repeat_count: cycle.nbDateRepeat,
      created_at: cycle.created_at,
      updated_at: cycle.updated_at
    }
  end

  def cycle_metrics(cycle)
    matches = cycle.user.matches.where(created_at: cycle.startDate..cycle.endDate)
    total_matches = matches.count
    total_profit = matches.sum(:profit)
    total_energy = matches.sum(:energyUsed)

    {
      matches_stats: {
        total_matches: total_matches,
        total_profit: total_profit,
        average_profit: total_matches > 0 ? (total_profit / total_matches).round(2) : 0,
        total_energy_spent: total_energy
      },
      efficiency: {
        profit_per_energy: total_energy > 0 ? (total_profit / total_energy).round(2) : 0,
        matches_per_day: total_matches > 0 ? (total_matches / ((cycle.endDate - cycle.startDate).to_i + 1).to_f).round(2) : 0
      },
      currency_earned: {
        total_bft: matches.sum(:totalToken),
        total_flex: matches.sum(:totalFee)
      }
    }
  end
end
