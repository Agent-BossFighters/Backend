class Api::V1::OpenLootController < ApplicationController
  def badges
    page = params[:page] || 1
    sort = params[:sort] || 'name:asc'

    response = OpenLootService.new.get_badges(page, sort)
    render json: response
  end

  def showrunner_contracts
    page = params[:page] || 1
    sort = params[:sort] || 'name:asc'

    response = OpenLootService.new.get_showrunner_contracts(page, sort)
    render json: response
  end
end
