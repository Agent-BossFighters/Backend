class Api::V1::ItemFarmingController < Api::V1::BaseController
  before_action :authenticate_user!

  def index
    @item_farmings = ItemFarming.includes(item: [ :type, :rarity ])
                               .where(items: { types: { name: [ "Badge", "Contract" ] } })

    render json: {
      farmings: @item_farmings.map { |farming| farming_json(farming) }
    }
  end

  def show
    @item_farming = ItemFarming.includes(item: [ :type, :rarity ]).find(params[:id])

    calculator = case @item_farming.item.type.name
    when "Badge"
      DataLab::BadgesMetricsCalculator.new(current_user)
    when "Contract"
      DataLab::ContractsMetricsCalculator.new(current_user)
    end

    metrics = calculator.calculate

    render json: {
      farming: farming_json(@item_farming),
      metrics: farming_metrics(@item_farming.item, metrics)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Farming data not found" }, status: :not_found
  end

  private

  def farming_json(farming)
    {
      id: farming.id,
      item: {
        id: farming.item.id,
        name: farming.item.name,
        type: farming.item.type.name,
        rarity: farming.item.rarity.name
      },
      efficiency: farming.efficiency,
      ratio: farming.ratio,
      in_game_time: farming.in_game_time
    }
  end

  def farming_metrics(item, metrics)
    case item.type.name
    when "Badge"
      badge_metrics = metrics[:badges_metrics].find { |m| m[:"1. rarity"] == item.rarity.name }
      {
        max_energy: badge_metrics[:"5. max_energy"],
        in_game_time: badge_metrics[:"7. in_game_time"],
        bft_per_minute: badge_metrics[:"9. bft_per_minute"],
        bft_per_max_charge: badge_metrics[:"10. bft_per_max_charge"],
        bft_value_per_max_charge: badge_metrics[:"11. bft_value_per_max_charge"]&.gsub("$", "")&.to_f
      }
    when "Contract"
      contract_metrics = metrics[:contracts].find { |m| m[:"1. rarity"] == item.rarity.name }
      {
        max_energy: contract_metrics[:"6. max_energy"],
        time_to_charge: contract_metrics[:"11. time_to_charge"],
        flex_charge: contract_metrics[:"12. flex_charge"],
        sp_marks_charge: contract_metrics[:"13. sp_marks_charge"]
      }
    end
  end
end
