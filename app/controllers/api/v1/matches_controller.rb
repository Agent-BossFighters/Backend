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
          render json: format_match_response(@match), status: :created
        else
          render json: {
            errors: @match.errors.full_messages,
            badge_errors: @match.badge_used.map { |b| b.errors.full_messages }.flatten
          }, status: :unprocessable_entity
        end
      end

      def update
        begin
          @match = Match.find(params[:id])

          unless @match.user_id == current_user.id
            return render json: { error: "Non autorisé" }, status: :unauthorized
          end

          if @match.update(match_params)
            render json: { match: match_json(@match) }
          else
            render json: {
              errors: @match.errors.full_messages,
              badge_errors: @match.badge_used.map { |b| b.errors.full_messages }.flatten
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

      def daily
        date = params[:date] ? Date.parse(params[:date]) : Date.current
        @matches = current_user.matches
                             .where("DATE(date) = ?", date)
                             .includes(:badge_used)
                             .order(created_at: :desc)

        render json: { matches: matches_json(@matches) }
      end

      def monthly
        date = params[:date] ? Date.parse(params[:date]) : Date.current
        start_date = date.beginning_of_month
        end_date = date.end_of_month

        @matches = current_user.matches
                             .where(date: start_date..end_date)
                             .includes(:badge_used)
                             .order(created_at: :desc)

        render json: { matches: matches_json(@matches) }
      end

      private

      def format_match_response(match)
        calculations = DataLab::MatchMetricsCalculator.new(match).calculate
        {
          match: {
            id: match.id,
            date: match.date,
            build: match.build,
            map: match.map,
            time: match.time,
            result: match.result,
            totalToken: match.totalToken,
            totalPremiumCurrency: match.totalPremiumCurrency,
            bonusMultiplier: match.bonusMultiplier,
            perksMultiplier: match.perksMultiplier,
            badge_used: match.badge_used.map { |badge| {
              slot: badge.slot,
              rarity: badge.rarity
            }},
            calculated: calculations
          }
        }
      end

      def match_json(match)
        calculations = DataLab::MatchMetricsCalculator.new(match).calculate

        {
          id: match.id,
          date: match.date,
          build: match.build,
          map: match.map,
          time: match.time,
          energyUsed: calculations[:energyUsed],
          result: match.result,
          totalToken: match.totalToken,
          totalPremiumCurrency: match.totalPremiumCurrency,
          bonusMultiplier: match.bonusMultiplier,
          perksMultiplier: match.perksMultiplier,
          luckrate: calculations[:luckrate],
          calculated: {
            energyCost: calculations[:energyCost],
            tokenValue: calculations[:tokenValue],
            premiumValue: calculations[:premiumValue],
            profit: calculations[:profit]
          },
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
          :build,
          :map,
          :time,
          :result,
          :totalToken,
          :totalPremiumCurrency,
          :bonusMultiplier,
          :perksMultiplier,
          badge_used_attributes: [:slot, :rarity, :_destroy]
        )
      end
    end
  end
end
