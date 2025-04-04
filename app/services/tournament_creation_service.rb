class TournamentCreationService
  attr_reader :errors

  def initialize(creator:, params:)
    @creator = creator
    @params = params
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      create_tournament
      assign_boss if survival_tournament?
      @tournament
    end
  rescue ActiveRecord::RecordInvalid => e
    @tournament = e.record
    @errors = @tournament.errors.full_messages
    false
  end

  private

  def create_tournament
    @tournament = Tournament.new(@params)
    @tournament.creator = @creator
    
    # Si c'est un tournoi de survie, définir le créateur comme boss par défaut
    if @params[:tournament_type].to_i == 0 || @params[:tournament_type].to_i == 1  # showtime_survival ou showtime_score
      @tournament.boss = @creator unless @params[:boss_id].present?
    end
    
    @tournament.save!
  end

  def assign_boss
    return unless @params[:boss_id]
    
    boss = User.find(@params[:boss_id])
    @tournament.update!(boss: boss)
  end

  def survival_tournament?
    @tournament.showtime_survival? || @tournament.showtime_score?
  end
end 