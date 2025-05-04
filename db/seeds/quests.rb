puts "Creating quests..."

# Supprimer toutes les quêtes existantes
Quest.destroy_all

# Quêtes Quotidiennes
Quest.create!(
  quest_id: 'daily_login',
  title: 'Daily Login',
  description: 'Log in to the game',
  quest_type: 'daily',
  xp_reward: 150,
  progress_required: 1,
  active: true
)

Quest.create!(
  quest_id: 'daily_matches',
  title: 'Daily Matches',
  description: 'Complete 5 matches today',
  quest_type: 'daily',
  xp_reward: 250,
  progress_required: 5,
  active: true
)
