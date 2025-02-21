module Api
  module V1
    class MatchesController < Api::V1::BaseController
      def index
        @matches = current_user.matches.includes(:badge_used).order(created_at: :desc)
        render json: { matches: matches_json(@matches) }
      end

      def create
        @match = current_user.matches.build(match_params)
        @match.date ||= DateTime.current

        Rails.logger.debug "Match attributes: #{@match.attributes.inspect}"
        Rails.logger.debug "Badge used attributes: #{@match.badge_used.map(&:attributes)}"

        # Calculate energyUsed before validation
        if @match.time.present? && @match.energyUsed.nil?
          @match.energyUsed = (@match.time.to_f / 10.0).round(2)
        end

        # Préparer les badges si non fournis
        if params[:match][:badge_used_attributes].blank?
          params[:match][:badge_used_attributes] = Array.new(5) { |i| { slot: i + 1, rarity: 'rare' } }
        end

        if @match.save
          render json: { match: match_json(@match) }, status: :created
        else
          Rails.logger.debug "Match errors: #{@match.errors.full_messages}"
          Rails.logger.debug "Badge errors: #{@match.badge_used.map { |b| b.errors.full_messages }}"
          render json: {
            errors: @match.errors.full_messages,
            badge_errors: @match.badge_used.map { |b| b.errors.full_messages }.flatten
          }, status: :unprocessable_entity
        end
      end

      def update
        @match = current_user.matches.find(params[:id])

        # Préparer les badges si non fournis
        if params[:match][:badge_used_attributes].blank?
          params[:match][:badge_used_attributes] = Array.new(5) { |i| { slot: i + 1, rarity: 'rare' } }
        end

        if @match.update(match_params)
          render json: { match: match_json(@match) }
        else
          render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Match introuvable" }, status: :not_found
      end

      def destroy
        @match = current_user.matches.find(params[:id])
        @match.destroy
        render json: { status: :ok }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Match introuvable" }, status: :not_found
      end

      def daily_metrics
        date = params[:date] ? Date.parse(params[:date]) : Date.current
        matches = current_user.matches
                           .where("DATE(date) = ?", date)
                           .includes(:badge_used)
                           .order(created_at: :asc)

        render json: { matches: matches_json(matches) }
      end

      private

      def match_json(match)
        {
          id: match.id,
          date: match.date,
          build: match.build,
          map: match.map,
          time: match.time,
          energyUsed: match.energyUsed,
          result: match.result,
          totalToken: match.totalToken,
          totalPremiumCurrency: match.totalPremiumCurrency,
          luckrate: match.luckrate,
          energyCost: match.energyCost,
          tokenValue: match.tokenValue,
          premiumCurrencyValue: match.premiumCurrencyValue,
          badge_used: match.badge_used.order(:slot).map { |badge|
            {
              id: badge.id,
              slot: badge.slot,
              rarity: badge.rarity,
              nftId: badge.nftId
            }
          }
        }
      end

      def matches_json(matches)
        matches.map { |match| match_json(match) }
      end

      def match_params
        params.require(:match).permit(
          :date,
          :map,
          :build,
          :time,
          :energyUsed,
          :result,
          :totalToken,
          :totalPremiumCurrency,
          :luckrate,
          :energyCost,
          :tokenValue,
          :premiumCurrencyValue,
          badge_used_attributes: [:id, :slot, :rarity, :nftId, :_destroy]
        ).tap do |whitelisted|
          # Valeurs par défaut pour les champs calculés
          whitelisted[:energyCost] ||= 1.49
          whitelisted[:tokenValue] ||= 0.01
          whitelisted[:premiumCurrencyValue] ||= 0.00744
        end
      end
    end
  end
end
