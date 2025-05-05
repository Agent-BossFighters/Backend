class Api::V1::ItemCraftingController < Api::V1::BaseController
  before_action :authenticate_user!

  def index
    @item_craftings = ItemCrafting.includes(item: [ :type, :rarity ])
                                 .where(items: { types: { name: [ "Badge", "Contract" ] } })

    render json: {
      craftings: @item_craftings.map { |crafting| crafting_json(crafting) }
    }
  end

  def show
    @item_crafting = ItemCrafting.includes(item: [ :type, :rarity ]).find(params[:id])

    calculator = case @item_crafting.item.type.name
    when "Badge"
      DataLab::BadgesMetricsCalculator.new(current_user)
    when "Contract"
      DataLab::ContractsMetricsCalculator.new(current_user)
    end

    metrics = calculator.calculate

    render json: {
      crafting: crafting_json(@item_crafting),
      metrics: crafting_metrics(@item_crafting.item, metrics)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Crafting data not found" }, status: :not_found
  end

  private

  def crafting_json(crafting)
    {
      id: crafting.id,
      item: {
        id: crafting.item.id,
        name: crafting.item.name,
        type: crafting.item.type.name,
        rarity: crafting.item.rarity.name
      },
      unit_to_craft: crafting.unit_to_craft,
      flex_craft: crafting.flex_craft,
      sponsor_mark_craft: crafting.sponsor_mark_craft,
      nb_lower_badge_to_craft: crafting.nb_lower_badge_to_craft
    }
  end

  def crafting_metrics(item, metrics)
    case item.type.name
    when "Badge"
      badge_metrics = metrics[:badges_metrics].find { |m| m[:"1. rarity"] == item.rarity.name }
      {
        total_cost: badge_metrics[:"4. floor_price"]&.gsub("$", "")&.to_f,
        in_game_minutes: calculate_in_game_minutes(badge_metrics[:"7. in_game_time"]),
        bft_per_max_charge: badge_metrics[:"10. bft_per_max_charge"],
        bft_value: badge_metrics[:"11. bft_value_per_max_charge"]&.gsub("$", "")&.to_f,
        roi: badge_metrics[:"12. roi"]
      }
    when "Contract"
      contract_metrics = metrics[:contracts].find { |m| m[:"1. rarity"] == item.rarity.name }
      {
        flex_craft: contract_metrics[:"9. flex_craft"],
        sp_marks_craft: contract_metrics[:"10. sp_marks_craft"],
        time_to_craft: contract_metrics[:"7. time_to_craft"],
        nb_badges_required: contract_metrics[:"8. nb_badges_required"]
      }
    end
  end

  private

  def calculate_in_game_minutes(time_str)
    return nil unless time_str
    hours = time_str.to_s.match(/(\d+)h/)[1].to_i
    hours * 60
  end
end
