class Api::V1::ShowrunnerContractsController < Api::V1::BaseController
  def index
    @items = Item.joins(:type, :rarity)
                 .where(types: { name: "Contract" })
                 .order("rarities.name ASC")

    render json: {
      contracts: @items.map { |item| contract_json(item) }
    }
  end

  def owned_contracts
    @nfts = Nft.joins(item: [ :type, :rarity ])
               .where(items: { type_id: Type.find_by(name: "Contract").id })
               .where(owner: current_user.id.to_s)
               .order("rarities.name ASC")

    render json: {
      contracts: @nfts.map { |nft| nft_json(nft) }
    }
  end

  def show
    @contract = Item.joins(:type, :rarity)
                   .includes(:item_crafting)  # Important pour les métriques de crafting
                   .where(types: { name: "Contract" })
                   .find(params[:id])

    render json: {
      contract: contract_json(@contract).merge(
        crafting_info: crafting_info(@contract)
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Contract not found" }, status: :not_found
  end

  def accept
    @contract = Item.joins(:type)
                   .where(types: { name: "Contract" })
                   .find(params[:id])

    # Vérifier la rareté maximale de l'utilisateur
    unless Rarity.where("name <= ?", current_user.maxRarity).include?(@contract.rarity)
      return render json: { error: "Contract rarity too high for your current level" }, status: :forbidden
    end

    # Vérifier si l'utilisateur a déjà ce contrat
    if current_user.nfts.exists?(itemId: @contract.id)
      return render json: { error: "Contract already owned" }, status: :unprocessable_entity
    end

    # Créer le NFT
    nft = Nft.new(
      itemId: @contract.id,
      issueId: "#{current_user.id}-#{@contract.id}-#{Nft.where(itemId: @contract.id).count + 1}",
      purchasePrice: @contract.floorPrice,
      owner: current_user.id.to_s
    )

    if nft.save
      render json: {
        message: "Contract accepted successfully",
        contract: contract_json(@contract)
      }
    else
      render json: { error: "Cannot accept this contract", details: nft.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Contract not found" }, status: :not_found
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

  def contract_json(item)
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

  def crafting_info(contract)
    return {} unless contract.item_crafting

    {
      unit_to_craft: contract.item_crafting.unit_to_craft,
      flex_cost: contract.item_crafting.flex_craft,
      sponsor_marks_cost: contract.item_crafting.sponsor_mark_craft,
      badges_required: contract.item_crafting.nb_lower_badge_to_craft
    }
  end
end
