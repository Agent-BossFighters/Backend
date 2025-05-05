class Api::V1::Admin::ItemsController < Api::V1::Admin::BaseController
  before_action :set_item, only: [ :show, :update, :destroy ]

  def index
    @items = Item.includes(:type, :rarity).all
    render json: @items.map { |item| item_json(item) }
  end

  def show
    render json: item_json(@item)
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      invalidate_admin_caches(:items)
      render json: item_json(@item), status: :created
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      invalidate_admin_caches(:items)
      render json: item_json(@item)
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    invalidate_admin_caches(:items)
    head :no_content
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :efficiency, :supply, :floorPrice, :type_id, :rarity_id)
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
end
