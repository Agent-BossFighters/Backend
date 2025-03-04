Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://agent-bossfighters.com'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end
