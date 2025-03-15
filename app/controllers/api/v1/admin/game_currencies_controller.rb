class Api::V1::Admin::GameCurrenciesController < Api::V1::Admin::BaseController
  def index
    @bft = Currency.find_by(symbol: 'BFT')
    @sponsor_marks = Currency.find_by(symbol: 'SM')
    
    render json: {
      bft: @bft,
      sponsor_marks: @sponsor_marks
    }
  end

  def update_bft
    @bft = Currency.find_by(symbol: 'BFT')
    
    if @bft.update(bft_params)
      render json: @bft
    else
      render json: { errors: @bft.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_sponsor_marks
    @sponsor_marks = Currency.find_by(symbol: 'SM')
    
    if @sponsor_marks.update(sponsor_marks_params)
      render json: @sponsor_marks
    else
      render json: { errors: @sponsor_marks.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def bft_params
    params.require(:bft).permit(:value, :exchange_rate)
  end

  def sponsor_marks_params
    params.require(:sponsor_marks).permit(:value, :exchange_rate)
  end
end
