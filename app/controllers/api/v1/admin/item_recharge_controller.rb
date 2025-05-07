module Api
  module V1
    module Admin
      class ItemRechargeController < BaseController
        before_action :set_item_recharge, only: [ :show, :update, :destroy ]

        def index
          @item_recharges = ItemRecharge.includes(item: [ :type, :rarity ]).all
          render json: @item_recharges.map { |recharge| recharge_json(recharge) }
        end

        def show
          render json: recharge_json(@item_recharge)
        end

        def create
          @item_recharge = ItemRecharge.new(item_recharge_params)
          if @item_recharge.save
            invalidate_caches
            render json: recharge_json(@item_recharge), status: :created
          else
            render json: { errors: @item_recharge.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @item_recharge.update(item_recharge_params)
            invalidate_caches
            render json: recharge_json(@item_recharge)
          else
            render json: { errors: @item_recharge.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @item_recharge.destroy
          invalidate_caches
          head :no_content
        end

        private

        def set_item_recharge
          @item_recharge = ItemRecharge.find(params[:id])
        end

        def item_recharge_params
          params.require(:item_recharge).permit(
            :item_id,
            :max_energy_recharge,
            :time_to_charge,
            :flex_charge,
            :sponsor_mark_charge,
            :unit_charge_cost,
            :max_charge_cost
          )
        end

        def recharge_json(recharge)
          {
            id: recharge.id,
            item: {
              id: recharge.item.id,
              name: recharge.item.name,
              type: recharge.item.type.name,
              rarity: recharge.item.rarity.name
            },
            max_energy_recharge: recharge.max_energy_recharge,
            time_to_charge: recharge.time_to_charge,
            flex_charge: recharge.flex_charge,
            sponsor_mark_charge: recharge.sponsor_mark_charge,
            unit_charge_cost: recharge.unit_charge_cost,
            max_charge_cost: recharge.max_charge_cost,
            created_at: recharge.created_at,
            updated_at: recharge.updated_at
          }
        end

        def invalidate_caches
          # Invalider les caches spécifiques aux badges et contrats
          invalidate_admin_caches(:items)
          Rails.cache.delete_matched("data_lab/badges/*")
          Rails.cache.delete_matched("data_lab/contracts/*")
          Rails.cache.delete_matched("data_lab/craft/*")
        end
      end
    end
  end
end
