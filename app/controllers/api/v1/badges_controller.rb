class Api::V1::BadgesController < Api::V1::BaseController
  def index
    @items = Item.joins(:type, :rarity)
                 .where(types: { name: "Badge" })
                 .order("rarities.name ASC")

    render json: {
      badges: @items.map { |item| badge_json(item) }
    }
  end

  def owned_badges
    @nfts = Nft.joins(item: [ :type, :rarity ])
               .where(items: { type_id: Type.find_by(name: "Badge").id })
               .where(owner: current_user.id.to_s)
               .order("rarities.name ASC")

    render json: {
      badges: @nfts.map { |nft| nft_json(nft) }
    }
  end

  def show
    @badge = Item.joins(:type, :rarity)
                .includes(:item_farming, :item_recharge)  # Important pour les métriques
                .where(types: { name: "Badge" })
                .find(params[:id])

    render json: {
      badge: badge_json(@badge).merge(
        farming_metrics: farming_metrics(@badge),
        recharge_info: recharge_info(@badge)
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Badge not found" }, status: :not_found
  end

  private

  def nft_json(nft)
    {
      id: nft.id,
      issueId: nft.issueId,
      itemId: nft.itemId,
      name: nft.item.name,
      type: nft.item.type.as_json(only: [ :id, :name ]),
      rarity: nft.item.rarity.as_json(only: [ :id, :name, :color ]),
      efficiency: nft.item.efficiency,
      supply: nft.item.supply,
      floorPrice: nft.item.floorPrice,
      purchasePrice: nft.purchasePrice,
      owner: nft.owner
    }
  end

  def badge_json(item)
    {
      id: item.id,
      name: item.name,
      rarity: item.rarity.as_json(only: [ :id, :name, :color ]),
      efficiency: item.efficiency,
      supply: item.supply,
      floorPrice: item.floorPrice,
      total_minted: item.nfts.count,
      available_supply: item.supply - item.nfts.count
    }
  end

  def farming_metrics(badge)
    return {} unless badge.item_farming

    {
      efficiency: badge.item_farming.efficiency,
      ratio: badge.item_farming.ratio,
      matches_per_charge: 6  # Valeur fixe selon le contexte
    }
  end

  def recharge_info(badge)
    return {} unless badge.item_recharge

    {
      max_energy: badge.item_recharge.max_energy_recharge,
      time_to_charge: badge.item_recharge.time_to_charge,
      flex_cost: badge.item_recharge.flex_charge,
      sponsor_marks_cost: badge.item_recharge.sponsor_mark_charge
    }
  end
end
