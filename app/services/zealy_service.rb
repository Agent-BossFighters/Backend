class ZealyService
  include HTTParty
  base_uri 'https://api-v2.zealy.io'

  def initialize
    @api_key = ENV['ZEALY_API_KEY']
    Rails.logger.info "Initializing ZealyService with API key: #{@api_key.present? ? 'Present' : 'Missing'}"
    raise "ZEALY_API_KEY is not configured" unless @api_key.present?

    @headers = {
      'x-api-key' => @api_key,
      'Content-Type' => 'application/json'
    }
  end

  def get_user_info(user_id)
    Rails.logger.info "Fetching user info for user_id: #{user_id}"
    response = HTTParty.get(
      "#{self.class.base_uri}/public/communities/agentbossfighterstest/users/#{user_id}",
      headers: @headers
    )
    handle_response(response)
  end

  def get_user_quests(user_id)
    Rails.logger.info "Fetching quests for user_id: #{user_id}"
    response = HTTParty.get(
      "#{self.class.base_uri}/public/communities/agentbossfighterstest/users/#{user_id}/quests",
      headers: @headers
    )
    handle_response(response)
  end

  def check_community_status(user_id)
    Rails.logger.info "Checking community status for user_id: #{user_id}"
    begin
      user_info = get_user_info(user_id)
      {
        joined: true,
        user: user_info
      }
    rescue => e
      Rails.logger.error("Error checking community status: #{e.message}")
      {
        joined: false,
        error: e.message
      }
    end
  end

  def sync_user_quests(user)
    Rails.logger.info "Syncing quests for user: #{user.id} with Zealy ID: #{user.zealy_user_id}"
    return unless user.zealy_user_id.present?

    # Récupérer les quêtes Zealy de l'utilisateur
    zealy_quests = get_user_quests(user.zealy_user_id)
    Rails.logger.info "Received #{zealy_quests.size} quests from Zealy"

    # Synchroniser les quêtes avec notre base de données
    zealy_quests.each do |zealy_quest|
      Rails.logger.info "Processing Zealy quest: #{zealy_quest['id']} - #{zealy_quest['name']}"
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

  private

  def handle_response(response)
    Rails.logger.info "Zealy API Response - Status: #{response.code}, Body: #{response.body}"
    case response.code
    when 200
      JSON.parse(response.body)
    when 401
      raise "Unauthorized: Invalid API key"
    when 404
      raise "Not found: Resource not found"
    else
      raise "API error: #{response.code} - #{response.body}"
    end
  end
end
