class OpenLootService
  include HTTParty
  base_uri "https://api.zenrows.com/v1"

  GAME_ID = "3af107fb-59f4-4859-b1f6-60a46b6a52bf"
  OPENLOOT_URL = "https://listing-api.openloot.com/v2"
  OPENLOOT_VAULT_URL = "https://vault-api.openloot.com/v2"
  ZENROWS_API_KEY = ENV["ZENROWS_API_KEY"]
  MAX_RETRIES = 3
  RETRY_DELAY = 5 # seconds
  JSON_DIRECTORY = Rails.root.join("data", "openloot")

  def initialize
    @options = {
      headers: {
        "Content-Type" => "application/json"
      }
    }
    # Créer le répertoire data/openloot s'il n'existe pas
    FileUtils.mkdir_p(JSON_DIRECTORY)

    # Log pour vérifier la clé API
    Rails.logger.info "ZenRows API Key: #{ZENROWS_API_KEY}"
  end

  def get_badges(page = 1, sort = "name:asc")
    response = get_listings("badge", page, sort)
    save_to_json("badges", response) if response && !response[:error]
    response
  end

  def get_showrunner_contracts(page = 1, sort = "name:asc")
    response = get_listings("showrunnercontract", page, sort)
    save_to_json("showrunner_contracts", response) if response && !response[:error]
    response
  end

  def get_all_listings(page_size = 100)
    Rails.logger.info "Fetching all listings with page size #{page_size}..."
    all_items = []
    page = 1
    total_pages = nil

    loop do
      response = get_listings(nil, page, "name:asc", page_size)
      break if response[:error]

      items = response["items"]
      all_items.concat(items) if items

      total_pages ||= response["totalPages"]
      break if !total_pages || page >= total_pages

      page += 1
      sleep(1) # Petit délai entre les requêtes pour éviter de surcharger l'API
    end

    save_to_json("all_listings", { items: all_items }) if all_items.any?
    { items: all_items }
  end

  def get_currency_stats(currency_id = "711bc69c-a9f2-4683-acd5-616a5eb7eead")
    Rails.logger.info "Fetching currency stats for #{currency_id}..."

    target_url = "#{OPENLOOT_VAULT_URL}/market/premium-currencies/#{currency_id}/stats"
    Rails.logger.info "Target URL: #{target_url}"

    response = self.class.get(
      "/",
      query: {
        "apikey" => ZENROWS_API_KEY,
        "url" => target_url,
        "antibot" => "true",
        "premium_proxy" => "true",
        "js_render" => "true",
        "wait" => "5000"
      }
    )

    Rails.logger.info "Currency stats response status: #{response.code}"

    begin
      parsed_response = JSON.parse(response.body)
      save_to_json("currency_stats_#{currency_id}", parsed_response)
      parsed_response
    rescue JSON::ParserError => e
      Rails.logger.error "Error parsing currency stats response: #{e.message}"
      { error: "Invalid JSON in currency stats response" }
    end
  end

  private

  def get_listings(tag = nil, page = 1, sort = "name:asc", page_size = 20)
    retries = 0
    begin
      Rails.logger.info "Fetching listings page #{page}..."

      # Construire l'URL complète pour OpenLoot
      url_params = {
        gameId: GAME_ID,
        page: page,
        sort: sort,
        pageSize: page_size
      }
      url_params[:tags] = tag if tag

      target_url = "#{OPENLOOT_URL}/market/listings?#{url_params.to_query}"
      Rails.logger.info "Target URL: #{target_url}"

      # Faire la requête via ZenRows
      Rails.logger.info "Sending request via ZenRows..."
      response = self.class.get(
        "/",
        query: {
          "apikey" => ZENROWS_API_KEY,
          "url" => target_url,
          "antibot" => "true",
          "premium_proxy" => "true",
          "js_render" => "true",
          "wait" => "5000"
        }
      )

      Rails.logger.info "ZenRows response status: #{response.code}"
      Rails.logger.info "ZenRows response body: #{response.body}"

      # Parser la réponse
      begin
        parsed_response = JSON.parse(response.body)
        Rails.logger.info "Successfully parsed response with #{parsed_response['items']&.size} items"
        parsed_response
      rescue JSON::ParserError => e
        Rails.logger.error "Error parsing response: #{e.message}"
        Rails.logger.error "Raw response: #{response.body}"
        { error: "Invalid JSON in OpenLoot API response" }
      end

    rescue => e
      Rails.logger.error "Error in get_listings: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      if (retries += 1) <= MAX_RETRIES
        Rails.logger.info "Retrying in #{RETRY_DELAY} seconds... (Attempt #{retries}/#{MAX_RETRIES})"
        sleep RETRY_DELAY
        retry
      end

      { error: e.message }
    end
  end

  def save_to_json(type, data)
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
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
