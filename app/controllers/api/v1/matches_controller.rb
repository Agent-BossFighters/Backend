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

        if @match.save
          render json: { match: match_json(@match) }, status: :created
        else
          render json: {
            errors: @match.errors.full_messages,
            badge_errors: @match.badge_used.map { |b| b.errors.full_messages }.flatten
          }, status: :unprocessable_entity
        end
      end

      def update
        begin
          @match = current_user.matches.find(params[:id])

          if @match.update(match_params)
            render json: { match: match_json(@match) }
          else
            render json: {
              errors: @match.errors.full_messages,
              badge_errors: @match.badge_used.map { |b| b.errors.full_messages }.flatten,
              received_params: match_params.to_h,
              validation_details: @match.errors.details
            }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Match introuvable" }, status: :not_found
        end
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

        render json: {
          matches: matches_json(matches),
          metrics: calculate_daily_metrics(matches)
        }
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
          bonusMultiplier: match.bonusMultiplier,
          perksMultiplier: match.perksMultiplier,
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

      def calculate_daily_metrics(matches)
        return {} if matches.empty?

        {
          total_matches: matches.count,
          total_energy: matches.sum(&:energyUsed),
          total_bft: matches.sum(&:totalToken),
          total_flex: matches.sum(&:totalPremiumCurrency),
          win_rate: calculate_win_rate(matches)
        }
      end

      def calculate_win_rate(matches)
        return 0 if matches.empty?
        ((matches.count { |m| m.result == 'win' } / matches.count.to_f) * 100).round(2)
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
          :slots,
          :bonusMultiplier,
          :perksMultiplier,
          badge_used_attributes: [:id, :slot, :rarity, :nftId, :_destroy]
        )
      end
    end
  end
end
