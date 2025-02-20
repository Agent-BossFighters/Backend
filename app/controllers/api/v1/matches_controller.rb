module Api
  module V1
    class MatchesController < Api::V1::BaseController
      before_action :set_match, only: [:show, :update, :destroy]
      before_action :calculate_financials, only: [:create, :update]

      def index
        @matches = current_user.matches.includes(:badge_used)
        render json: {
          matches: @matches.map { |match| match_json(match) }
        }
      end

      def show
        badge = @match.badge_used.first&.nft&.item
        metrics = badge ? calculate_badge_metrics(badge) : {}

        render json: {
          match: match_json(@match),
          metrics: {
            combat_stats: combat_stats_json(@match),
            time_efficiency: @match.profit / @match.time,
            badge_metrics: metrics,
            multipliers: multipliers_json(@match, metrics)
          },
          rewards: calculate_match_rewards
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Match not found" }, status: :not_found
      end

      def create
        @match = current_user.matches.build(match_params)
        @match.date ||= DateTime.current

        if @match.save
          if params[:badges].present?
            params[:badges].each do |badge|
              @match.badge_used.create(nftId: badge[:nft_id])
            end
          end

          render json: {
            status: :created,
            match: match_json(@match),
            daily_metrics: DataLab::DailyMetricsCalculator.new(current_user, @match.date.to_date).calculate
          }
        else
          render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @match.update(match_params)
          if params[:badges].present?
            @match.badge_used.destroy_all
            params[:badges].each do |badge|
              @match.badge_used.create(nftId: badge[:nft_id])
            end
          end

          render json: {
            status: :ok,
            match: match_json(@match),
            daily_metrics: DataLab::DailyMetricsCalculator.new(current_user, @match.date.to_date).calculate
          }
        else
          render json: { errors: @match.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Match not found" }, status: :not_found
      end

      def destroy
        begin
          @match = current_user.matches.find(params[:id])
          match_date = @match.date.to_date
          @match.destroy

          render json: {
            status: :ok,
            daily_metrics: DataLab::DailyMetricsCalculator.new(current_user, match_date).calculate
          }
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: "Match not found",
            details: "Le match avec l'ID #{params[:id]} n'existe pas ou n'appartient pas à l'utilisateur courant"
          }, status: :not_found
        end
      end

      def daily_metrics
        date = params[:date] ? Date.parse(params[:date]) : Date.current
        render json: {
          date: date,
          metrics: DataLab::DailyMetricsCalculator.new(current_user, date).calculate
        }
      end

      private

      def calculate_financials
        # Récupérer le build de l'utilisateur
        build_name = params[:match][:build].is_a?(ActionController::Parameters) ? params[:match][:build][:buildName] : params[:match][:build]
        user_build = current_user.user_builds.find_by(buildName: build_name)

        # Mettre à jour le build dans les paramètres pour qu'il soit juste le nom
        params[:match][:build] = build_name

        # Calcul du coût total
        total_cost = 0

        # Coût des frais
        if params[:match][:totalFee].present? && params[:match][:feeCost].present?
          total_cost += params[:match][:totalFee].to_f * params[:match][:feeCost].to_f
        end

        # Coût de l'énergie
        if params[:match][:energyUsed].present? && params[:match][:energyCost].present?
          total_cost += params[:match][:energyUsed].to_f * params[:match][:energyCost].to_f
        end

        # Calcul des gains
        total_earnings = 0

        # Valeur des tokens BFT
        if params[:match][:totalToken].present? && params[:match][:tokenValue].present?
          total_earnings += params[:match][:totalToken].to_f * params[:match][:tokenValue].to_f
        end

        # Valeur des tokens FLEX
        if params[:match][:totalPremiumCurrency].present? && params[:match][:premiumCurrencyValue].present?
          total_earnings += params[:match][:totalPremiumCurrency].to_f * params[:match][:premiumCurrencyValue].to_f
        end

        # Calcul du profit de base (avant multiplicateurs)
        base_profit = total_earnings - total_cost

        # Application des multiplicateurs du build
        total_profit = base_profit
        if user_build
          total_profit *= user_build.bonusMultiplier.to_f * user_build.perksMultiplier.to_f
        end

        params[:match][:profit] = total_profit.round(2)
      end

      def set_match
        @match = current_user.matches.find(params[:id])
      end

      def match_json(match)
        user_build = current_user.user_builds.find_by(buildName: match.build)
        multipliers = if user_build
          {
            bonus: user_build.bonusMultiplier,
            perks: user_build.perksMultiplier
          }
        else
          {
            bonus: 1.0,
            perks: 1.0
          }
        end

        {
          id: match.id,
          build: match.build,
          date: match.date,
          map: match.map,
          totalFee: match.totalFee,
          feeCost: match.feeCost,
          slots: match.slots,
          luckrate: match.luckrate,
          time: match.time,
          energyUsed: match.energyUsed,
          energyCost: match.energyCost,
          totalToken: match.totalToken,
          tokenValue: match.tokenValue,
          totalPremiumCurrency: match.totalPremiumCurrency,
          premiumCurrencyValue: match.premiumCurrencyValue,
          profit: match.profit,
          bonusMultiplier: multipliers[:bonus],
          perksMultiplier: multipliers[:perks],
          badges: match.badge_used.map { |badge| badge_used_json(badge) }
        }
      end

      def badge_used_json(badge_used)
        {
          id: badge_used.id,
          nftId: badge_used.nftId
        }
      end

      def combat_stats_json(match)
        {
          damage_dealt: match.damage_dealt,
          damage_taken: match.damage_taken,
          critical_hits: match.critical_hits
        }
      end

      def multipliers_json(match, metrics)
        user_build = current_user.user_builds.find_by(buildName: match.build)
        {
          bonus: user_build&.bonusMultiplier || 1.0,
          perks: user_build&.perksMultiplier || 1.0,
          badge: metrics[:efficiency]
        }
      end

      def calculate_badge_metrics(badge)
        return {} unless badge
        {
          efficiency: badge.efficiency,
          rarity: badge.rarity.name,
          level: badge.level
        }
      end

      def calculate_match_rewards
        {
          currencies: {
            bft: @match.totalToken,
            flex: @match.totalPremiumCurrency
          },
          total_profit: @match.profit
        }
      end

      def match_params
        params.require(:match).permit(
          :build,
          :date,
          :map,
          :totalFee,
          :feeCost,
          :slots,
          :luckrate,
          :time,
          :energyUsed,
          :energyCost,
          :totalToken,
          :tokenValue,
          :totalPremiumCurrency,
          :premiumCurrencyValue,
          :profit
        )
      end
    end
  end
end
