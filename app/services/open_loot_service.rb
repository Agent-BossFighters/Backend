class OpenLootService
  include HTTParty
  base_uri 'https://listing-api.openloot.com/v2'

  GAME_ID = '3af107fb-59f4-4859-b1f6-60a46b6a52bf'
  FLARE_BYPASS_URL = 'http://localhost:8080/v1'
  MAX_RETRIES = 3
  RETRY_DELAY = 5 # seconds
  JSON_DIRECTORY = Rails.root.join('data', 'openloot')

  def initialize
    @options = {
      headers: {
        'Content-Type' => 'application/json'
      }
    }
    # Créer le répertoire data/openloot s'il n'existe pas
    FileUtils.mkdir_p(JSON_DIRECTORY)
  end

  def get_badges(page = 1, sort = 'name:asc')
    response = get_listings('badge', page, sort)
    save_to_json('badges', response) if response && !response[:error]
    response
  end

  def get_showrunner_contracts(page = 1, sort = 'name:asc')
    response = get_listings('showrunnercontract', page, sort)
    save_to_json('showrunner_contracts', response) if response && !response[:error]
    response
  end

  private

  def get_listings(tag, page = 1, sort = 'name:asc')
    retries = 0
    begin
      Rails.logger.info "Fetching #{tag} listings page #{page}..."

      # Construire l'URL complète
      full_url = "#{self.class.base_uri}/market/listings?gameId=#{GAME_ID}&page=#{page}&sort=#{sort}&tags=#{tag}"
      Rails.logger.info "Full URL: #{full_url}"

      # Faire la requête au bypass service
      Rails.logger.info "Sending request to bypass service..."
      response = HTTParty.post(
        FLARE_BYPASS_URL,
        body: {
          cmd: 'request.get',
          url: full_url,
          maxTimeout: 60000
        }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )

      Rails.logger.info "Bypass service response status: #{response.code}"
      Rails.logger.info "Bypass service response body: #{response.body}"

      # Parser la réponse
      data = JSON.parse(response.body)

      if data['status'] == 'ok' && data['solution'] && data['solution']['response']
        begin
          # Extraire le JSON de la balise <pre>
          html_response = data['solution']['response']
          if html_response.include?('<pre>')
            json_text = html_response.match(/<pre>(.*?)<\/pre>/m)&.[](1)
            if json_text
              parsed_response = JSON.parse(json_text)
              Rails.logger.info "Successfully parsed response with #{parsed_response['items']&.size} items"
              parsed_response
            else
              Rails.logger.error "Could not extract JSON from HTML response"
              { error: 'Could not extract JSON from HTML response' }
            end
          else
            parsed_response = JSON.parse(html_response)
            Rails.logger.info "Successfully parsed response with #{parsed_response['items']&.size} items"
            parsed_response
          end
        rescue JSON::ParserError => e
          Rails.logger.error "Error parsing solution response: #{e.message}"
          Rails.logger.error "Raw solution response: #{data['solution']['response']}"
          { error: 'Invalid JSON in OpenLoot API response' }
        end
      else
        Rails.logger.error "Invalid bypass service response format"
        Rails.logger.error "Response data: #{data.inspect}"
        { error: 'Invalid response from bypass service' }
      end

    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error in get_listings: #{e.message}"
      Rails.logger.error "Raw response body: #{response&.body}"
      { error: 'Invalid JSON response' }
    rescue => e
      Rails.logger.error "Error in get_listings: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { error: e.message }
    end
  end

  def bypass_cloudflare(url)
    Rails.logger.info "Sending request to FlareBypasser for URL: #{url}"

    begin
      response = HTTParty.post(
        FLARE_BYPASS_URL,
        body: {
          cmd: 'request.get',
          url: url,
          maxTimeout: 60000
        }.to_json,
        headers: { 'Content-Type': 'application/json' },
        timeout: 65 # Légèrement plus que maxTimeout
      )

      JSON.parse(response.body)
    rescue Net::ReadTimeout => e
      { 'status' => 'error', 'message' => 'Bypass timeout' }
    rescue JSON::ParserError => e
      { 'status' => 'error', 'message' => 'Invalid JSON response from bypass service' }
    rescue => e
      { 'status' => 'error', 'message' => e.message }
    end
  end

  def format_cookies(cookies)
    cookies.map { |c| "#{c['name']}=#{c['value']}" }.join('; ')
  end

  def save_to_json(type, data)
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "#{type}_#{timestamp}.json"
    filepath = JSON_DIRECTORY.join(filename)

    Rails.logger.info "Saving #{type} data to #{filepath}..."

    begin
      File.write(filepath, JSON.pretty_generate(data))
      Rails.logger.info "Successfully saved data to #{filepath}"
    rescue => e
      Rails.logger.error "Error saving data to JSON: #{e.message}"
    end
  end
end
