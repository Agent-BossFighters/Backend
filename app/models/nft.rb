class Nft < ApplicationRecord
  belongs_to :item, foreign_key: :itemId
  has_many :badge_used
  has_many :matches, through: :badge_used

  # Méthode pour faciliter l'accès à l'utilisateur
  def user
    User.find_by(id: owner)
  end
end
