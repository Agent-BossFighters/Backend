module Api
  module V1
    module Admin
      class ForgeSettingsController < BaseController
        before_action :set_forge_setting, only: [:show, :update, :destroy]

        def index
          settings = ForgeSetting.includes(:rarity).references(:rarity).order('rarities.id ASC')
          render json: settings.map { |s| json_for(s) }
        end

        def show
          render json: json_for(@forge_setting)
        end

        def create
          setting = ForgeSetting.new(forge_setting_params)
          if setting.save
            invalidate_caches
            render json: json_for(setting), status: :created
          else
            render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @forge_setting.update(forge_setting_params)
            invalidate_caches
            render json: json_for(@forge_setting)
          else
            render json: { errors: @forge_setting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @forge_setting.destroy
          invalidate_caches
          head :no_content
        end

        private

        def set_forge_setting
          @forge_setting = ForgeSetting.find(params[:id])
        end

        def forge_setting_params
          params.require(:forge_setting).permit(
            :rarity_id,
            :operation_type,
            :supply,
            :nb_previous_required,
            :nb_digital_required,
            :cash,
            :fusion_core,
            :bft_tokens,
            :sponsor_marks_reward
          )
        end

        def json_for(setting)
          {
            id: setting.id,
            rarity: setting.rarity.name,
            rarity_id: setting.rarity_id,
            operation_type: setting.operation_type,
            supply: setting.supply,
            nb_previous_required: setting.nb_previous_required,
            nb_digital_required: setting.nb_digital_required,
            cash: setting.cash,
            fusion_core: setting.fusion_core,
            bft_tokens: setting.bft_tokens,
            sponsor_marks_reward: setting.sponsor_marks_reward,
            created_at: setting.created_at,
            updated_at: setting.updated_at
          }
        end

        def invalidate_caches
          Rails.cache.delete_matched("data_lab/forge/*")
        end
      end
    end
  end
end


