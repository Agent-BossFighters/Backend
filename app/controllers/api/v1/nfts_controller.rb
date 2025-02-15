class Api::V1::NftsController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :json

  def index
    @nfts = Nft.joins(item: [ :type, :rarity ])

    # Filtrage par type si spécifié
    @nfts = @nfts.where(items: { type_id: Type.find_by(name: params[:type]).id }) if params[:type].present?

    # Filtrage par propriétaire si spécifié
    @nfts = @nfts.where(owner: current_user.id.to_s) if params[:owned].present?

    # Tri par date de création décroissante
    @nfts = @nfts.order("nfts.created_at DESC")

    render json: {
      nfts: @nfts.map { |nft| nft_json(nft) }
    }
  end

  def show
    @nft = Nft.joins(item: [ :type, :rarity ]).find(params[:id])
    render json: { nft: nft_json(@nft) }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "NFT not found" }, status: :not_found
  end

  def create
    # Vérifier si l'item existe
    item = Item.joins(:rarity).find_by(id: nft_params[:itemId])
    return render json: { error: "Item not found." }, status: :unprocessable_entity unless item

    @nft = Nft.new(
      itemId: item.id,
      issueId: nft_params[:issueId],
      purchasePrice: nft_params[:purchasePrice] || item.floorPrice,
      owner: current_user.id.to_s
    )

    if @nft.save
      render json: { nft: nft_json(@nft) }, status: :created
    else
      render json: { error: @nft.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @nft = Nft.find(params[:id])

    # Vérification de la propriété
    unless @nft.owner == current_user.id.to_s
      return render json: { error: "You don't own this NFT" }, status: :forbidden
    end

    if @nft.update(nft_params)
      render json: { nft: nft_json(@nft) }
    else
      render json: { error: @nft.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "NFT not found" }, status: :not_found
  end

  def destroy
    @nft = Nft.find(params[:id])

    # Vérification de la propriété
    unless @nft.owner == current_user.id.to_s
      return render json: { error: "You don't own this NFT" }, status: :forbidden
    end

    # Vérification de l'utilisation dans un match
    if BadgeUsed.exists?(nftId: @nft.id)
      return render json: { error: "This NFT is currently in use in a match" }, status: :unprocessable_entity
    end

    @nft.destroy
    render json: { message: "NFT successfully deleted" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "NFT not found" }, status: :not_found
  end

  private

  def nft_params
    params.require(:nft).permit(:itemId, :issueId, :purchasePrice)
  end

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
end
