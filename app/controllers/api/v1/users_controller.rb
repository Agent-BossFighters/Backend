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
    # Vérifier si le mot de passe actuel est fourni
    unless params[:user][:current_password].present?
      return render json: { error: "Le mot de passe actuel est requis" }, status: :unprocessable_entity
    end

    # Vérifier si le mot de passe est correct
    unless current_user.valid_password?(params[:user][:current_password])
      return render json: { error: "Le mot de passe actuel est incorrect" }, status: :unauthorized
    end
    
    # Créer les paramètres de mise à jour
    update_params = user_params
    
    # Si un nouveau mot de passe est fourni, l'ajouter aux paramètres
    if params[:user][:password].present?
      update_params = update_params.merge(password: params[:user][:password])
    end
    
    # Mettre à jour l'utilisateur
    if current_user.update(update_params)
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
    # Permettre username, email et autres attributs si nécessaire, mais pas current_password
    params.require(:user).permit(:username, :email, :isPremium, :level, :experience,
    :assetType, :asset, :slotUnlockedId, :maxRarity)
  end
end
