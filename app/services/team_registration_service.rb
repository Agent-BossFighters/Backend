class TeamRegistrationService
  attr_reader :errors, :team

  def initialize(tournament:, captain:, params:)
    @tournament = tournament
    @captain = captain
    @params = params
    @errors = []
  end

  def call
    return false unless can_register?

    ActiveRecord::Base.transaction do
      create_team
      generate_invitation_code if @params[:generate_code]
      @team.save!
      true
    end

    @team
  rescue ActiveRecord::RecordInvalid => e
    @errors = @team.errors.full_messages
    false
  end

  private

  def can_register?
    return add_error('Tournament is full') if tournament_full?
    return add_error('Invalid entry code') if tournament_requires_code? && !valid_entry_code?
    return add_error('Level requirement not met') if level_requirement_not_met?
    true
  end

  def create_team
    @team = @tournament.teams.build(
      name: @params[:name],
      captain: @captain
    )
  end

  def generate_invitation_code
    code = SecureRandom.hex(4)
    @team.invitation_code = code
  end

  def tournament_full?
    @tournament.teams.count >= @tournament.max_teams
  end

  def tournament_requires_code?
    @tournament.entry_code.present?
  end

  def valid_entry_code?
    @params[:entry_code] == @tournament.entry_code
  end

  def level_requirement_not_met?
    @tournament.agent_level_required > 0 && @captain.level < @tournament.agent_level_required
  end

  def add_error(message)
    @errors << message
    false
  end
end 