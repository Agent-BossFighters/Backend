module Api
  module V1
    class SummariesController < Api::V1::BaseController
      def daily
        date = params[:date] ? Date.parse(params[:date]) : Date.current
        matches = current_user.matches.where("DATE(date) = ?", date)

        total_calculations = matches.map { |m| DataLab::MatchMetricsCalculator.new(m).calculate }

        render json: {
          matchesCount: matches.count,
          energyUsed: {
            amount: total_calculations.sum { |c| c[:energyUsed] }.round(2),
            cost: total_calculations.sum { |c| c[:energyCost] }.round(2)
          },
          totalBft: {
            amount: matches.sum(&:totalToken).to_f.round(2),
            value: total_calculations.sum { |c| c[:tokenValue] }.round(2)
          },
          totalFlex: {
            amount: matches.sum(&:totalPremiumCurrency).to_f.round(2),
            value: total_calculations.sum { |c| c[:premiumValue] }.round(2)
          },
          profit: total_calculations.sum { |c| c[:profit] }.round(2),
          results: {
            win: matches.where(result: "win").count,
            loss: matches.where(result: "loss").count,
            draw: matches.where(result: "draw").count
          }
        }
      end

      def monthly
        begin
          date = if params[:date]
                   raise Date::Error, "Format de date invalide. Utilisez YYYY-MM" unless params[:date].match?(/^\d{4}-\d{2}$/)
                   Date.parse("#{params[:date]}-01")
          else
                   Date.current
          end

          start_date = date.beginning_of_month
          end_date = date.end_of_month

          matches = current_user.matches.where(date: start_date..end_date)
          total_calculations = matches.map { |m| DataLab::MatchMetricsCalculator.new(m).calculate }

          render json: {
            total_matches: matches.count,
            total_energy: total_calculations.sum { |c| c[:energyUsed] }.round(2),
            total_energy_cost: total_calculations.sum { |c| c[:energyCost] }.round(2),
            total_bft: {
              amount: matches.sum(&:totalToken).to_f.round(2),
              value: total_calculations.sum { |c| c[:tokenValue] }.round(2)
            },
            total_flex: {
              amount: matches.sum(&:totalPremiumCurrency).to_f.round(2),
              value: total_calculations.sum { |c| c[:premiumValue] }.round(2)
            },
            profit: total_calculations.sum { |c| c[:profit] }.round(2),
            results: {
              win: matches.where(result: "win").count,
              loss: matches.where(result: "loss").count,
              draw: matches.where(result: "draw").count
            }
          }
        rescue Date::Error => e
          render json: { error: e.message }, status: :bad_request
        end
      end
    end
  end
end
