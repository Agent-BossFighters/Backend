class Api::V1::ItemsController < Api::V1::BaseController
  def index
    @items = Item.includes(:type, :rarity)

    # Filtrage par type
    @items = @items.where(type_id: Type.find_by(name: params[:type_name]).id) if params[:type_name].present?

    # Filtrage par rareté
    @items = @items.where(rarity_id: Rarity.find_by(name: params[:rarity_name]).id) if params[:rarity_name].present?

    # Filtrage par rareté maximale de l'utilisateur
    if params[:user_accessible].present? && current_user
      @items = @items.joins(:rarity)
                    .where("rarities.name <= ?", current_user.maxRarity)
    end

    render json: {
      items: @items.map { |item| item_json(item) }
    }
  end

  def show
    @item = Item.includes(:type, :rarity).find(params[:id])

    render json: {
      item: item_json(@item).merge(
        market_data: market_data(@item)
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item not found" }, status: :not_found
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      render json: { item: item_json(@item) }, status: :created
    else
      render json: { error: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @item = Item.find(params[:id])

    if @item.update(item_params)
      render json: { item: item_json(@item) }
    else
      render json: { error: @item.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item not found" }, status: :not_found
  end

  def destroy
    @item = Item.find(params[:id])

    # Vérifier si l'item a des NFTs associés
    if @item.nfts.exists?
      return render json: { error: "Cannot delete item with existing NFTs" }, status: :unprocessable_entity
    end

    @item.destroy
    render json: { message: "Item successfully deleted" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item not found" }, status: :not_found
  end

  private

  def item_params
    params.require(:item).permit(
      :name,
      :efficiency,
      :supply,
      :floorPrice,
      :type_id,
      :rarity_id
    )
  end

  def item_json(item)
    {
      id: item.id,
      name: item.name,
      type: item.type.as_json(only: [ :id, :name ]),
      rarity: item.rarity.as_json(only: [ :id, :name, :color ]),
      efficiency: item.efficiency,
      supply: item.supply,
      floorPrice: item.floorPrice,
      total_minted: item.nfts.count
    }
  end

  def market_data(item)
    {
      supply: {
        total: item.supply,
        minted: item.nfts.count,
        available: item.supply - item.nfts.count
      },
      price: {
        floor: item.floorPrice,
        last_sold: item.nfts.order(created_at: :desc).first&.purchasePrice
      }
    }
  end
end
