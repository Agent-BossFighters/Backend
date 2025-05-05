class Api::V1::Admin::CurrenciesController < Api::V1::Admin::BaseController
  before_action :set_currency, only: [ :show, :update, :destroy ]

  def index
    @currencies = Currency.all
    render json: @currencies
  end

  def show
    render json: @currency
  end

  def update
    if @currency.update(currency_params)
      render json: @currency
    else
      render json: { errors: @currency.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    @currency = Currency.new(currency_params)
    if @currency.save
      render json: @currency, status: :created
    else
      render json: { errors: @currency.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @currency.destroy
    head :no_content
  end

  private

  def set_currency
    @currency = Currency.find(params[:id])
  end

  def currency_params
    params.require(:currency).permit(:name, :symbol, :price, :exchange_rate, :game_id)
  end
end
