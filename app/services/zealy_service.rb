class ZealyService
  include HTTParty
  base_uri "https://api-v2.zealy.io"

  # Limite de taux : 50 requêtes par seconde
  RATE_LIMIT = 50
  RATE_WINDOW = 1.second

  def initialize
    @api_key = ENV["ZEALY_API_KEY"]
    @subdomain = "agentbossfighterstest"
    Rails.logger.info "Initializing ZealyService with API key: #{@api_key.present? ? 'Present' : 'Missing'}"
    raise "ZEALY_API_KEY is not configured" unless @api_key.present?

    @headers = {
      "x-api-key" => @api_key,
      "Content-Type" => "application/json",
      "Accept" => "*/*"
    }
  end

  def get_user_info(user_id)
    with_rate_limiting do
      response = HTTParty.get(
        "#{self.class.base_uri}/public/communities/#{@subdomain}/users/#{user_id}",
        headers: @headers
      )
      handle_response(response)
    end
  end

  def get_user_quests(user_id)
    with_rate_limiting do
      response = HTTParty.get(
        "#{self.class.base_uri}/public/communities/#{@subdomain}/quests",
        headers: @headers,
        query: { userId: user_id }
      )
      handle_response(response)
    end
  end

  def check_community_status(user_id)
    with_rate_limiting do
      begin
        user_info = get_user_info(user_id)
        quests = get_user_quests(user_id)

        {
          joined: user_info.present? && user_info["id"].present?,
          quest_completed: quests.any? { |quest|
            quest["name"] == "Join the Agent's community on Zealy" &&
            quest["status"] == "success"
          },
          user: user_info
        }
      rescue => e
        Rails.logger.error("Error checking community status: #{e.message}")
        { joined: false, quest_completed: false, error: e.message }
      end
    end
  end

  def sync_user_quests(user)
    with_rate_limiting do
      return { success: false, error: "No Zealy ID" } unless user.zealy_user_id.present?

      begin
        zealy_quests = get_user_quests(user.zealy_user_id)
        Rails.logger.info "Received #{zealy_quests.size} quests from Zealy"

        zealy_quests.each do |zealy_quest|
          quest = Quest.find_or_initialize_by(zealy_quest_id: zealy_quest["id"])
          quest.update!(
            title: zealy_quest["name"],
            description: zealy_quest["description"],
            xp_reward: zealy_quest["xp"],
            progress_required: 1,
            quest_type: "social",
            active: true
          )
        end
        { success: true }
      rescue => e
        Rails.logger.error("Failed to sync Zealy quests: #{e.message}")
        { success: false, error: e.message }
      end
    end
  end

  def add_xp(user_id, xp, label = nil, description = nil)
    with_rate_limiting do
      response = HTTParty.post(
        "#{self.class.base_uri}/public/communities/#{@subdomain}/users/#{user_id}/xp",
        headers: @headers,
        body: {
          xp: xp,
          label: label,
          description: description
        }.to_json
      )
      handle_response(response)
    end
  end

  def remove_xp(user_id, xp, label = nil, description = nil)
    with_rate_limiting do
      response = HTTParty.delete(
        "#{self.class.base_uri}/public/communities/#{@subdomain}/users/#{user_id}/xp",
        headers: @headers,
        body: {
          xp: xp,
          label: label,
          description: description
        }.to_json
      )
      handle_response(response)
    end
  end

  def ban_user(user_id, reason)
    with_rate_limiting do
      response = HTTParty.post(
        "#{self.class.base_uri}/public/communities/#{@subdomain}/users/#{user_id}/ban",
        headers: @headers,
        body: { reason: reason }.to_json
      )
      handle_response(response)
    end
  end

  def member_of_community?(zealy_user_id)
    response = HTTParty.post(
      "#{self.class.base_uri}/public/communities/#{@subdomain}/member",
      headers: @headers,
      body: { userId: zealy_user_id }.to_json
    )
    Rails.logger.info "Zealy member check response: #{response.code} - #{response.body}"
    response.code == 200
  end

  def quest_completed_on_zealy?(zealy_user_id, zealy_quest_id)
    response = HTTParty.get(
      "#{self.class.base_uri}/public/communities/#{@subdomain}/reviews",
      headers: @headers,
      query: {
        userId: zealy_user_id,
        questId: zealy_quest_id,
        status: "success"
      }
    )
    items = JSON.parse(response.body)["items"] rescue []
    items.any?
  end

  private

  def with_rate_limiting
    sleep(1.0 / RATE_LIMIT) if RATE_LIMIT > 0
    yield
  end

  def handle_response(response)
    Rails.logger.info "Zealy API Response - Status: #{response.code}, Body: #{response.body}"
    case response.code
    when 200, 204
      response.body.present? ? JSON.parse(response.body) : true
    when 401
      raise "Unauthorized: Invalid API key"
    when 403
      raise "Forbidden: Insufficient permissions"
    when 404
      raise "Not found: Resource not found"
    when 409
      raise "Conflict: Resource already exists"
    when 429
      raise "Rate limit exceeded"
    else
      raise "API error: #{response.code} - #{response.body}"
    end
  end
end
