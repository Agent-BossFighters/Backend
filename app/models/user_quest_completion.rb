class UserQuestCompletion < ApplicationRecord
  # Relations
  belongs_to :user
  belongs_to :quest, foreign_key: :quest_id, primary_key: :quest_id

  # Validations
  validates :user_id, presence: true
  validates :quest_id, presence: true
  validates :progress, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :completion_date, presence: true
  validates :user_id, uniqueness: { 
    scope: [:quest_id, :completion_date],
    message: "a déjà une progression pour cette quête à cette date" 
  }

  # Callbacks
  before_validation :set_completion_date
  after_save :update_user_experience_if_completed

  # Méthodes d'instance
  def completed?
    progress >= quest.progress_required
  end

  private

  def set_completion_date
    self.completion_date ||= Date.current
  end

  def update_user_experience_if_completed
    
    # Vérifier si la quête vient d'être complétée ou si on force l'attribution d'XP
    is_newly_completed = completed? && 
                         saved_change_to_progress? && 
                         (progress_was.nil? || progress_was.to_i < quest.progress_required)
    
    if is_newly_completed
      
      # Sauvegarder l'état avant mise à jour
      old_experience = user.experience.to_f || 0.0
      old_level = user.level || 1
      
      # Ajouter l'XP en utilisant update_columns pour contourner les callbacks
      new_experience = old_experience + quest.xp_reward
      
      success = user.update_columns(experience: new_experience)
      
      # Vérifier si l'utilisateur doit monter de niveau
      check_level_up
      
      # Recharger l'utilisateur pour obtenir les dernières valeurs
      user.reload
      
    end
  end

  def check_level_up
    
    # Recharger l'utilisateur pour être sûr d'avoir les dernières valeurs
    user.reload
    
    current_exp = user.experience.to_f || 0.0
    current_level = user.level || 1

    # Formule : chaque niveau nécessite level * 1000 XP
    next_level_exp = current_level * 1000

    # Tant que l'utilisateur a assez d'XP pour passer au niveau suivant
    level_increased = false
    
    while current_exp >= next_level_exp
      # Incrémenter le niveau
      level_before = current_level
      
      # Mettre à jour directement dans la base de données avec update_columns
      new_level = current_level + 1
      success = user.update_columns(level: new_level)
      
      level_increased = true
      
      # Mettre à jour la référence du niveau
      user.reload
      current_level = user.level
      current_exp = user.experience.to_f
      
      # Recalculer l'XP nécessaire pour le prochain niveau
      next_level_exp = current_level * 1000
    end
  end
end 