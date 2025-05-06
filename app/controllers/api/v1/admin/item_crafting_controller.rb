module Api
  module V1
    module Admin
      class ItemCraftingController < BaseController
        before_action :set_item_crafting, only: [ :show, :update, :destroy ]

        def index
          @item_craftings = ItemCrafting.includes(item: [ :type, :rarity ]).all
          render json: @item_craftings.map { |crafting| crafting_json(crafting) }
        end

        def show
          render json: crafting_json(@item_crafting)
        end

        def create
          @item_crafting = ItemCrafting.new(item_crafting_params)
          if @item_crafting.save
            render json: crafting_json(@item_crafting), status: :created
          else
            render json: { errors: @item_crafting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @item_crafting.update(item_crafting_params)
            render json: crafting_json(@item_crafting)
          else
            render json: { errors: @item_crafting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @item_crafting.destroy
          head :no_content
        end

        private

        def set_item_crafting
          @item_crafting = ItemCrafting.find(params[:id])
        end

        def item_crafting_params
          params.require(:item_crafting).permit(
            :item_id,
            :unit_to_craft,
            :flex_craft,
            :sponsor_mark_craft,
            :nb_lower_badge_to_craft,
            :craft_time,
            :max_level
          )
        end

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
            nb_lower_badge_to_craft: crafting.nb_lower_badge_to_craft,
            craft_time: crafting.craft_time,
            max_level: crafting.max_level,
            created_at: crafting.created_at,
            updated_at: crafting.updated_at
          }
        end
      end
    end
  end
end
