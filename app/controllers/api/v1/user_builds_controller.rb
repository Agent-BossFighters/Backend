class Api::V1::UserBuildsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_build, only: [:show, :update, :destroy]

  def index
    @builds = current_user.user_builds
    render json: {
      builds: @builds.map { |build| build_json(build) },
      total_builds: @builds.count
    }
  end

  def show
    render json: {
      build: build_json(@build),
      performance: calculate_build_metrics
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Build not found or not accessible" }, status: :not_found
  end

  def create
    @build = current_user.user_builds.new(build_params)

    if build_params[:buildName].blank?
      return render json: { error: "Build name cannot be empty" }, status: :unprocessable_entity
    end

    if current_user.user_builds.exists?(buildName: build_params[:buildName])
      return render json: { error: "Build name already exists" }, status: :unprocessable_entity
    end

    if @build.save
      render json: { build: build_json(@build) }, status: :created
    else
      render json: { error: @build.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    old_build_name = @build.buildName

    if @build.update(build_params)
      # Si le nom du build a changé, mettre à jour tous les matchs associés
      if old_build_name != @build.buildName
        matches_updated = current_user.matches.where(build: old_build_name).update_all(build: @build.buildName)
        Rails.logger.info "Updated #{matches_updated} matches from '#{old_build_name}' to '#{@build.buildName}'"
      end

      render json: { build: build_json(@build) }
    else
      render json: { error: @build.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Build not found or not accessible" }, status: :not_found
  end

  def destroy
    @build.destroy
    render json: { message: "Build successfully deleted" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Build not found or not accessible" }, status: :not_found
  end

  private

  def set_build
    @build = current_user.user_builds.find(params[:id])
  end

  def build_json(build)
    {
      id: build.id,
      buildName: build.buildName,
      bftBonus: build.bftBonus,  # Valeur brute sans transformation
      created_at: build.created_at,
      updated_at: build.updated_at
    }
  end

  def calculate_build_metrics
    matches = Match.where(build: @build.buildName).last(10)
    return {} if matches.empty?

    {
      recent_performance: {
        average_profit: matches.sum(&:profit) / matches.size,
        total_bft: matches.sum(&:totalToken),
        total_flex: matches.sum(&:totalFee),
        matches_count: matches.size
      }
    }
  end

  def build_params
    params.require(:user_build).permit(:buildName, :bftBonus)
  end
end
