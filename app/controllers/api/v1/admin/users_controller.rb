class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  def index
    @users = User.all
    render json: @users
  end

  def show
    @user = User.find(params[:id])
    render json: @user
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def promote
    @user = User.find(params[:id])
    @user.make_admin!
    render json: @user
  end

  def demote
    @user = User.find(params[:id])
    @user.revoke_admin!
    render json: @user
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :isPremium, :is_admin)
  end
end
