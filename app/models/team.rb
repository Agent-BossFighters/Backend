class Team < ApplicationRecord
  # Relations
  belongs_to :tournament
  belongs_to :captain, class_name: 'User', optional: true
  has_many :team_members, dependent: :destroy do
    # Observer pour mettre à jour is_empty lorsque des membres sont ajoutés ou supprimés
    def after_add(team_member)
      proxy_association.owner.update_column(:is_empty, false) if proxy_association.owner.is_empty
    end
    
    def after_remove(team_member)
      proxy_association.owner.update_column(:is_empty, true) if proxy_association.owner.team_members.count == 0
    end
  end
  has_many :players, through: :team_members, source: :player
  has_many :matches_as_team1, class_name: 'Match', foreign_key: 'team1_id'
  has_many :matches_as_team2, class_name: 'Match', foreign_key: 'team2_id'

  # Callbacks
  after_create :add_captain_as_member

  # Validations
  validates :name, presence: true
  validates :invitation_code, uniqueness: { scope: :tournament_id }, allow_nil: true
  validate :captain_meets_requirements, on: :create
  validate :validate_team_size

  # Scopes
  scope :with_member, ->(user_id) { joins(:team_members).where(team_members: { user_id: user_id }) }

  # Ajouter le counter_cache pour team_members
  def self.reset_counters(id)
    team = find(id)
    Team.update_counters team.id, team_members_count: team.team_members.count
  end

  def matches
    Match.where('team1_id = ? OR team2_id = ?', id, id)
  end

  def full?
    return false unless tournament
    team_members.count >= tournament.players_per_team
  end

  def has_complete_team?
    team_members.count >= tournament.min_players_per_team
  end

  def is_alive?
    return true unless tournament&.survival?
    team_members.exists?(is_boss_eligible: true)
  end

  def is_member?(user)
    team_members.exists?(user_id: user.id)
  end

  def generate_invitation_code
    loop do
      self.invitation_code = SecureRandom.alphanumeric(6).upcase
      break unless Team.exists?(invitation_code: self.invitation_code)
    end
    save
  end

  def next_available_slot
    return 1 if team_members.empty?
    
    # Trouver le premier slot disponible
    max_slots = tournament ? tournament.players_per_team : 5
    (1..max_slots).detect do |slot|
      !team_members.exists?(slot_number: slot)
    end || 1  # Retourner 1 si aucun slot libre (ne devrait pas arriver si full? est vérifié avant)
  end

  def members_count
    team_members.count
  end

  private

  def add_captain_as_member
    # Ne rien faire si pas de capitaine
    return unless captain_id.present?    

    # Ne pas ajouter le capitaine comme membre s'il est créateur ou administrateur du tournoi
    return if tournament&.tournament_admins&.exists?(user_id: captain_id)
    
    team_members.create!(
      user_id: captain_id,
      slot_number: 1,
      is_boss_eligible: tournament.survival? || tournament.arena?
    )
  end

  def captain_meets_requirements
    # Ne rien faire si pas de capitaine
    return unless captain_id.present?
    
    if tournament.agent_level_required > 0 && captain && captain.level < tournament.agent_level_required
      errors.add(:captain, "does not meet the minimum level requirement")
    end
  end

  def validate_team_size
    return unless tournament
    
    if tournament.survival? || tournament.arena?
      if team_members.count > tournament.players_per_team
        errors.add(:base, "Team cannot have more than #{tournament.players_per_team} members")
      end
    end
  end

  def players_not_boss_if_survival
    return unless tournament&.survival?
    
    boss_eligible_count = team_members.where(is_boss_eligible: true).count
    if boss_eligible_count == 0
      errors.add(:base, "Team must have at least one boss-eligible player")
    end
  end
end 