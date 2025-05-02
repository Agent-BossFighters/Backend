puts "Creating quests..."

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

# Quêtes Sociales
Quest.create!(
  quest_id: 'zealy_connect',
  title: 'Join the Agent\'s community on Zealy',
  description: 'Connect to Zealy and follow our community!',
  quest_type: 'social',
  xp_reward: 100,
  progress_required: 1,
  active: true,
  icon_url: 'zealy.png'
)

Quest.create!(
  quest_id: 'twitter_follow_and_interact',
  title: 'Follow us on X',
  description: 'Follow @ThibaultLENORM2 on X! (Like, Retweet, Reply)',
  quest_type: 'social',
  xp_reward: 300,
  progress_required: 1,
  active: true
)
