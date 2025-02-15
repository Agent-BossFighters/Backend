class Api::V1::UsersController < Api::V1::BaseController
  def index
    @users = User.all
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: {
      user: @user,
      stats: calculate_user_stats,
      assets: get_user_assets
    }
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if current_user.update(user_params)
      render json: current_user
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.destroy
      render json: { message: 'User successfully deleted' }, status: :ok
    else
      render json: { error: 'Failed to delete user' }, status: :unprocessable_entity
    end
  end

  def delete_profile
    if current_user&.destroy
      render json: { message: 'Profile successfully deleted' }, status: :ok
    else
      render json: { error: 'Failed to delete profile' }, status: :unprocessable_entity
    end
  end

  private

  def calculate_user_stats
    matches = @user.matches
    {
      total_matches: matches.count,
      total_profit: matches.sum(:profit),
      total_energy: matches.sum(:energyUsed),
      total_token: matches.sum(:totalToken),
      level_stats: {
        current_level: @user.level,
        experience: @user.experience
      }
    }
  end

  def get_user_assets
    {
      builds: @user.user_builds.count,
      badges: @user.nfts.count,
      slots: @user.user_slots.count
    }
  end

  def user_params
    params.require(:user).permit(
      :username, :isPremium, :level, :experience,
      :assetType, :asset, :slotUnlockedId, :maxRarity
    )
  end
end
