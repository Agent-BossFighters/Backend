module Api
  module V1
    module Admin
      class PerksLockSettingsController < BaseController
        before_action :set_setting, only: [:show, :update, :destroy]

        def index
          settings = PerksLockSetting.includes(:rarity).order('rarities.id ASC')
          render json: settings.map { |s| json_for(s) }
        end

        def show
          render json: json_for(@setting)
        end

        def create
          setting = PerksLockSetting.new(setting_params)
          if setting.save
            render json: json_for(setting), status: :created
          else
            render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @setting.update(setting_params)
            render json: json_for(@setting)
          else
            render json: { errors: @setting.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @setting.destroy
          head :no_content
        end

        private

        def set_setting
          @setting = PerksLockSetting.find(params[:id])
        end

        def setting_params
          params.require(:perks_lock_setting).permit(:rarity_id, :star_0, :star_1, :star_2, :star_3)
        end

        def json_for(s)
          {
            id: s.id,
            rarity_id: s.rarity_id,
            rarity: s.rarity.name,
            star_0: s.star_0,
            star_1: s.star_1,
            star_2: s.star_2,
            star_3: s.star_3
          }
        end
      end
    end
  end
end


