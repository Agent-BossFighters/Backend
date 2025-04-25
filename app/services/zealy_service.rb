class ZealyService
  include HTTParty
  base_uri 'https://api-v2.zealy.io'

  def initialize
    @api_key = ENV['ZEALY_API_KEY']
    @headers = {
      'x-api-key' => @api_key,
      'Content-Type' => 'application/json'
    }
  end

  def get_user_info(user_id)
    response = HTTParty.get(
      "#{base_uri}/public/communities/agentbossfighterstest/users/#{user_id}",
      headers: @headers
    )
    JSON.parse(response.body)
  end

  def get_user_quests(user_id)
    response = HTTParty.get(
      "#{base_uri}/public/communities/agentbossfighterstest/users/#{user_id}/quests",
      headers: @headers
    )
    JSON.parse(response.body)
  end

  def sync_user_quests(user)
    # Récupérer les quêtes Zealy de l'utilisateur
    zealy_quests = get_user_quests(user.zealy_user_id)

    # Synchroniser les quêtes avec notre base de données
    zealy_quests.each do |zealy_quest|
      quest = Quest.find_or_initialize_by(zealy_quest_id: zealy_quest['id'])
      quest.update!(
        title: zealy_quest['name'],
        description: zealy_quest['description'],
        xp_reward: zealy_quest['xp'],
        progress_required: 1,
        quest_type: 'social',
        active: true
      )
    end
  end
end
