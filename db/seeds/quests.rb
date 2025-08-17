puts "Creating or updating quests..."

quests = [
  {
    quest_id: 'daily_login',
    title: 'Daily Login',
    description: 'Log in to the game',
    quest_type: 'daily',
    xp_reward: 150,
    progress_required: 1,
    active: true
  },
  {
    quest_id: 'daily_matches',
    title: 'Daily Matches',
    description: 'Complete 5 matches today',
    quest_type: 'daily',
    xp_reward: 250,
    progress_required: 5,
    active: true
  }
]

quests.each do |attrs|
  quest = Quest.find_or_initialize_by(quest_id: attrs[:quest_id])
  quest.update!(attrs)
end

puts "✓ Quests upserted successfully"
