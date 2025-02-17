# app/controllers/api/v1/data_lab_controller.rb
class Api::V1::DataLabController < ApplicationController
  before_action :authenticate_user!

  def slots_metrics
    response = Rails.cache.fetch("data_lab/slots/#{current_user.id}/#{params[:badge_rarity]}", expires_in: 1.hour) do
      DataLab::SlotsMetricsCalculator.new(current_user, params[:badge_rarity]).calculate
    end

    render json: response
  end

  def contracts_metrics
    response = Rails.cache.fetch("data_lab/contracts/#{current_user.id}", expires_in: 1.hour) do
      DataLab::ContractsMetricsCalculator.new(current_user).calculate
    end

    render json: response
  end

  def badges_metrics
    calculator = DataLab::BadgesMetricsCalculator.new(current_user)
    render json: calculator.calculate
  end

  def craft_metrics
    calculator = DataLab::CraftMetricsCalculator.new(current_user)
    render json: calculator.calculate
  end

  def currency_metrics
    calculator = DataLab::CurrencyMetricsCalculator.new(current_user)
    render json: calculator.calculate
  end
end
