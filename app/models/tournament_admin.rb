class TournamentAdmin < ApplicationRecord
  # Relations
  belongs_to :tournament
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :tournament_id }
  validate :creator_cannot_be_removed

  # Scopes
  scope :creators, -> { where(is_creator: true) }

  private

  def creator_cannot_be_removed
    if is_creator_was && !is_creator
      errors.add(:is_creator, "creator status cannot be removed")
    end
  end
end 