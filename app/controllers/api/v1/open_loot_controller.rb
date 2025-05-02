class Api::V1::OpenLootController < ApplicationController
  def badges
    page = params[:page] || 1
    sort = params[:sort] || "name:asc"

    response = OpenLootService.new.get_badges(page, sort)
    render json: response
  end

  def showrunner_contracts
    page = params[:page] || 1
    sort = params[:sort] || "name:asc"

    response = OpenLootService.new.get_showrunner_contracts(page, sort)
    render json: response
  end

  def all_listings
    page_size = params[:page_size] || 100
    response = OpenLootService.new.get_all_listings(page_size)
    render json: response
  end

  def currency_stats
    currency_id = params[:currency_id] || "711bc69c-a9f2-4683-acd5-616a5eb7eead"
    response = OpenLootService.new.get_currency_stats(currency_id)
    render json: response
  end
end
