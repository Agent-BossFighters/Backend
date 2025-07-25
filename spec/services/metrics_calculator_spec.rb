require 'rails_helper'

RSpec.describe MetricsCalculator do
  let(:user) { create(:user) }

  describe 'Badge Metrics' do
    [ 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic' ].each do |rarity_name|
      context "with #{rarity_name} badge" do
        let(:item) { create(:item, :badge, rarity_name: rarity_name) }
        let(:calculator) { described_class.new(item, user) }
        let(:metrics) { calculator.calculate_badge_metrics }

        it 'calculates correct base metrics' do
          base_metrics = described_class::BASE_METRICS[rarity_name]
          expect(metrics[:efficiency]).to eq(base_metrics[:efficiency])
          expect(metrics[:ratio]).to eq(base_metrics[:ratio])
          expect(metrics[:max_charges]).to eq(base_metrics[:charges])
          expect(metrics[:matches_per_charge]).to eq(base_metrics[:matches_per_charge])
          expect(metrics[:matches_per_day]).to eq(base_metrics[:matches_per_day])
        end

        it 'calculates correct farming metrics' do
          base_metrics = described_class::BASE_METRICS[rarity_name]
          expect(metrics[:bft_per_minute]).to eq(base_metrics[:bft_per_minute])
          expect(metrics[:bft_per_charge]).to eq(base_metrics[:bft_per_charge])
          expect(metrics[:bft_per_day]).to eq(base_metrics[:bft_per_day])
        end

        it 'calculates correct crafting metrics' do
          base_metrics = described_class::BASE_METRICS[rarity_name]
          expect(metrics[:craft_time]).to eq(base_metrics[:craft_time])
          expect(metrics[:flex_craft_cost]).to eq(base_metrics[:flex_craft])
          expect(metrics[:sponsor_marks_cost]).to eq(base_metrics[:sponsor_marks])
        end

        it 'calculates correct recharge metrics' do
          recharge_costs = described_class::RECHARGE_COSTS[rarity_name]
          expect(metrics[:recharge_costs][:single_charge][:flex]).to eq(recharge_costs[:single])
          expect(metrics[:recharge_costs][:single_charge][:sponsor_marks]).to eq(recharge_costs[:sponsor_marks_required])
          expect(metrics[:recharge_costs][:full_charges][:flex]).to eq(recharge_costs[:full])
        end

        it 'calculates correct USD values' do
          base_metrics = described_class::BASE_METRICS[rarity_name]
          flex_cost = base_metrics[:flex_craft] * described_class::FLEX_TO_USD
          sm_cost = base_metrics[:sponsor_marks] * described_class::SM_TO_USD
          expected_total = (flex_cost + sm_cost).round(2)

          expect(metrics[:total_craft_cost_usd]).to eq(expected_total)
        end
      end
    end
  end

  describe 'ROI Calculations' do
    let(:badge) { create(:badge, item: create(:item, :badge, rarity_name: 'Epic')) }
    let(:calculator) { described_class.new(badge.item) }
    let(:metrics) { calculator.calculate_badge_metrics }

    it 'calculates matches needed for ROI' do
      matches_to_roi = (badge.item.floorPrice / metrics[:bft_per_charge]).ceil
      expect(matches_to_roi).to be > 0
      expect(matches_to_roi).to eq((badge.item.floorPrice / 3600).ceil) # 3600 est le bft_per_charge pour Epic
    end

    it 'calculates days needed for ROI' do
      matches_to_roi = (badge.item.floorPrice / metrics[:bft_per_charge]).ceil
      days_to_roi = (matches_to_roi.to_f / metrics[:matches_per_day]).ceil
      expect(days_to_roi).to be > 0
      expect(days_to_roi).to eq((matches_to_roi.to_f / 24).ceil) # 24 matches par jour pour Epic
    end

    context 'with zero or negative profit' do
      before { allow(badge.item).to receive(:floorPrice).and_return(0) }

      it 'handles edge cases correctly' do
        expect(metrics[:roi_days]).to eq(Float::INFINITY)
      end
    end
  end

  describe '#calculate_match_metrics' do
    let(:match) { create(:match, user: user) }

    it 'calcule correctement les métriques de match' do
      metrics = described_class.new(match).calculate_match_metrics

      expect(metrics[:tokens_earned]).to eq(match.totalToken)
      expect(metrics[:premium_earned]).to eq(match.totalPremiumCurrency)
      expect(metrics[:profit]).to eq(400)
      expect(metrics[:efficiency_ratio]).to eq(match.totalToken.to_f / match.energyUsed)
    end
  end

  describe 'Match Performance' do
    let(:match) { create(:match, user: user) }
    let(:badge) { create(:badge, item: create(:item, :badge, rarity_name: 'Epic')) }

    it 'calculates correct match metrics' do
      calculator = described_class.new(badge.item)
      metrics = calculator.calculate_badge_metrics

      expect(metrics[:efficiency]).to eq(12.92)
      expect(metrics[:bft_per_charge]).to eq(3600)
      expect(metrics[:matches_per_charge]).to eq(6)
      expect(match.profit).to be_present
    end
  end

  describe 'Player Cycle Analysis' do
    let(:cycle) { create(:player_cycle, user: user) }
    let(:badge) { create(:badge, item: create(:item, :badge, rarity_name: 'Epic')) }
    let(:matches) { create_list(:match, 3, user: cycle.user) }

    before do
      matches.each do |match|
        match.update!(date: cycle.startDate + 1.hour)
      end
    end

    it 'calculates correct cycle metrics' do
      calculator = described_class.new(cycle)
      metrics = calculator.calculate_cycle_metrics

      expect(metrics[:total_matches]).to eq(3)
      expect(metrics[:total_profit]).to eq(1200) # 3 matches * 400 profit
      expect(metrics[:average_profit_per_match]).to eq(400)
      expect(metrics[:total_tokens_earned]).to eq(3000) # 3 matches * 1000 tokens
      expect(metrics[:total_premium_earned]).to eq(30) # 3 matches * 10 premium
      expect(metrics[:average_efficiency_ratio]).to eq(1000.0 / 50.0) # totalToken / energyUsed
    end
  end
end
