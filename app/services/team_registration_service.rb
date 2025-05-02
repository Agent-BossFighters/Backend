class TeamRegistrationService
  attr_reader :errors, :team

  def initialize(tournament:, user:, team_params:)
    @tournament = tournament
    @user = user
    @team_params = team_params
    @errors = []
  end

  def call
    @team = nil
    @errors = []

    # Vérifier les codes d'entrée et d'invitation
    return false unless validate_codes

    # Récupérer l'équipe par ID ou code d'invitation
    find_team

    # Vérifier si l'utilisateur est autorisé à s'inscrire
    return false unless can_register?

    return false if @errors.any?

    if @team.present?
      # Cas d'un joueur rejoignant une équipe existante
      create_team_member
    else
      # Cas de la création d'une nouvelle équipe
      create_team
    end

    @errors.empty?
  end

  private

  def validate_codes
    # Vérifier le code d'entrée du tournoi si nécessaire
    if @tournament.entry_code.present?
      if @team_params[:entry_code].blank?
        add_error("Tournament entry code is required")
        return false
      end

      unless @tournament.entry_code === @team_params[:entry_code]
        add_error("Invalid tournament entry code")
        return false
      end
    end

    # Vérifier le code d'invitation si l'équipe est privée
    if @team_params[:id].present?
      team = @tournament.teams.find_by(id: @team_params[:id])
      if team&.invitation_code.present?
        if @team_params[:invitation_code].blank?
          add_error("Team invitation code is required")
          return false
        end

        unless team.invitation_code === @team_params[:invitation_code]
          add_error("Invalid team invitation code")
          return false
        end
      end
    end

    true
  end

  def can_register?
    return add_error("Tournament is not open for registration") unless @tournament.registration_open?
    return add_error("Tournament is full") if tournament_full?
    return add_error("User does not meet level requirement") if @tournament.agent_level_required > @user.level
    true
  end

  def find_team
    return if @team_params.nil? || (@team_params[:id].blank? && @team_params[:invitation_code].blank? && @team_params[:team_letter].blank?)

    if @team_params[:invitation_code].present?
      @team = @tournament.teams.find_by(invitation_code: @team_params[:invitation_code])
      add_error("Invalid invitation code") if @team.nil?
    elsif @team_params[:id].present? && @team_params[:id] != "id"
      @team = @tournament.teams.find_by(id: @team_params[:id])
      add_error("Team not found") if @team.nil?
    elsif @team_params[:team_letter].present?
      # Utiliser la lettre comme nom de l'équipe (Team A, Team B, etc.)
      team_name = "Team #{@team_params[:team_letter]}"
      @team = @tournament.teams.find_by(name: team_name)
      add_error("Team not found with name #{team_name}") if @team.nil?
    end
  end

  def create_team
    begin
      ActiveRecord::Base.transaction do
        # Créer l'équipe avec les attributs fournis
        @team = Team.new(
          tournament: @tournament,
          name: @team_params[:name],
          description: @team_params[:description],
          captain: @user,
          private: @team_params[:private] || false
        )

        # Générer un code d'invitation si demandé
        @team.generate_invitation_code if @team_params[:private]

        unless @team.save
          @team.errors.full_messages.each { |msg| add_error(msg) }
          raise ActiveRecord::Rollback
        end
      end
    rescue => e
      add_error(e.message)
    end

    @errors.empty?
  end

  def create_team_member
    begin
      # Vérifier si l'équipe est pleine
      if @team.full?
        add_error("Team is full")
        return false
      end

      # Vérifier si l'utilisateur est déjà membre de l'équipe
      if @team.is_member?(@user)
        add_error("User is already a member of this team")
        return false
      end

      # Vérifier si le slot demandé est déjà pris
      if @team_params[:slot_number].present? && @team.team_members.exists?(slot_number: @team_params[:slot_number])
        add_error("Requested slot is already taken")
        return false
      end

      # Assigner un slot disponible si non spécifié
      slot_number = @team_params[:slot_number] || @team.next_available_slot

      # Vérifier si c'est la première personne à rejoindre l'équipe
      is_first_member = @team.is_empty

      # Mettre à jour le statut is_empty et définir le capitaine si c'est la première personne à rejoindre
      ActiveRecord::Base.transaction do
        # Si l'équipe est vide et n'a pas de capitaine, définir ce joueur comme capitaine
        if is_first_member && @team.captain_id.nil?
          @team.update_column(:captain_id, @user.id)

          # Si la request contient private et que c'est true, générer un code d'invitation
          if @team_params[:private] == true || @team_params[:private] == "true" ||
             @team_params[:is_private] == true || @team_params[:is_private] == "true"
            @team.generate_invitation_code
          end
        end

        # Mettre à jour is_empty directement en SQL pour éviter les validations
        if @team.is_empty
          Team.where(id: @team.id).update_all(is_empty: false)
        end

        # Créer le membre d'équipe
        team_member = @team.team_members.build(
          user_id: @user.id,
          slot_number: slot_number,
          is_boss_eligible: @tournament.survival? || @tournament.arena?
        )

        unless team_member.save
          team_member.errors.full_messages.each { |msg| add_error(msg) }
          raise ActiveRecord::Rollback
        end
      end
    rescue => e
      add_error(e.message)
      return false
    end

    true
  end

  def players_not_boss_if_survival?(slot_number)
    @tournament.survival? && slot_number > 1 && @user.level >= @tournament.agent_level_required
  end

  def tournament_full?
    # Ne considérer le tournoi comme plein que si l'équipe n'existe pas (création d'une nouvelle équipe)
    @team.nil? && @tournament.teams.count >= @tournament.max_teams
  end

  def slot_taken?(team)
    team.team_members.exists?(slot_number: @team_params[:slot_number])
  end

  def valid_slot?(slot_number)
    slot_number.present? &&
    slot_number.between?(1, @tournament.players_per_team)
  end

  def add_error(message)
    @errors << message
    nil
  end
end
