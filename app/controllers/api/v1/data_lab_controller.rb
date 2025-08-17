# app/controllers/api/v1/data_lab_controller.rb
class Api::V1::DataLabController < ApplicationController
  before_action :authenticate_user!

  def slots_metrics
    game = Game.find_by(name: "Boss Fighters")
    slots_version = Slot.where(game: game).maximum(:updated_at)&.to_i || 0
    cache_key = "data_lab/slots/#{current_user.id}/#{params[:badge_rarity]}/#{slots_version}"
    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      DataLab::SlotsMetricsCalculator.new(current_user, params[:badge_rarity]).calculate
    end

    render json: response
  end

  def contracts_metrics
    cache_key = "data_lab/contracts/#{current_user.id}"
    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      DataLab::ContractsMetricsCalculator.new(current_user).calculate
    end

    render json: response
  end

  def badges_metrics
    slots_used = (params[:slots_used] || "1").to_i
    bft_multiplier = (params[:bft_multiplier] || "1.0").to_f
    cache_key = "data_lab/badges/#{current_user.id}/#{slots_used}/#{bft_multiplier}"

    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      calculator = DataLab::BadgesMetricsCalculator.new(current_user, slots_used, bft_multiplier)
      calculator.calculate
    end

    render json: response
  end

  def craft_metrics
    cache_key = "data_lab/craft/#{current_user.id}"
    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      DataLab::CraftMetricsCalculator.new(current_user).calculate
    end

    render json: response
  end

  def forge_metrics
    type = params[:type].presence || "merge"
    item = params[:item].presence || "digital"

    version = [ForgeSetting.maximum(:updated_at), Rarity.maximum(:updated_at)].compact.max&.to_i || 0
    cache_key = "data_lab/forge/#{current_user.id}/#{type}/#{item}/#{version}"
    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      DataLab::ForgeMetricsCalculator.new(current_user).calculate(type: type, item: item)
    end

    render json: response
  end

  def perks_lock
    settings = PerksLockSetting.includes(:rarity).order('rarities.id ASC')
    render json: settings.map { |s| {
      "RARITY": s.rarity.name,
      "NO STAR": s.star_0 || 0,
      "1 STAR": s.star_1 || 0,
      "2 STARS": s.star_2 || 0,
      "3 STARS": s.star_3 || 0
    }}
  end

  def currency_metrics
    cache_key = "data_lab/currency/#{current_user.id}"
    response = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      DataLab::CurrencyMetricsCalculator.new(current_user).calculate
    end

    render json: response
  end
end
