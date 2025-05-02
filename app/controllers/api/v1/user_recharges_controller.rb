class Api::V1::UserRechargesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_recharge, only: [ :show, :update ]

  VALID_DISCOUNT_TIMES = [ 5, 9, 10, 13, 16, 20, 25 ].freeze

  def index
    @recharges = current_user.user_recharges
    render json: {
      recharges: @recharges.map { |recharge| recharge_json(recharge) },
      total_discounts: current_user.user_recharges.sum(:discountNumber),
      stats: {
        active_discounts: current_user.user_recharges.where('"discountNumber" > 0').count,
        total_discount_time: current_user.user_recharges.sum('("discountTime" * "discountNumber")')
      }
    }
  end

  def show
    render json: {
      recharge: recharge_json(@recharge),
      usage_stats: calculate_usage_stats
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Recharge discount not found or not accessible" }, status: :not_found
  end

  def create
    @recharge = current_user.user_recharges.new(recharge_params)

    if @recharge.save
      render json: { recharge: recharge_json(@recharge) }, status: :created
    else
      render json: { error: @recharge.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @recharge.update(recharge_params)
      render json: { recharge: recharge_json(@recharge) }
    else
      render json: { error: @recharge.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Recharge discount not found or not accessible" }, status: :not_found
  end

  private

  def set_recharge
    @recharge = current_user.user_recharges.find(params[:id])
  end

  def recharge_params
    params.require(:user_recharge).permit(:discountNumber, :discountTime)
  end

  def recharge_json(recharge)
    {
      id: recharge.id,
      discountTime: recharge.discountTime,
      discountNumber: recharge.discountNumber,
      description: get_discount_description(recharge.discountTime),
      total_discount_time: recharge.discountTime * recharge.discountNumber,
      created_at: recharge.created_at,
      updated_at: recharge.updated_at
    }
  end

  def calculate_usage_stats
    {
      total_uses: @recharge.discountNumber,
      remaining_uses: [ @recharge.discountNumber, 0 ].max,
      total_time_saved: @recharge.discountTime * @recharge.discountNumber
    }
  end

  def get_discount_description(discount_time)
    case discount_time
    when 25 then "Legendary Rowdy Fighter Discount"
    when 20 then "Gladiator Rowdy Fighter Discount"
    when 16 then "Fighter Rowdy Fighter Discount"
    when 13 then "Challenger Rowdy Fighter Discount"
    when 10 then "Debutant Rowdy Fighter Discount"
    when 9 then "Tournament Winner Discount"
    when 5 then "Alpha Fighter Discount"
    else "Standard Discount"
    end
  end
end
