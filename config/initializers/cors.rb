Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    #origins_list = [ENV['FRONTEND_URL']] # URL de production from .env

    origins_list = 'http://localhost:3000','https://api.stripe.com','https://agent-bossfighters.com/'

    # Ajouter les URLs de développement si on est en environnement de développement
    if Rails.env.development?
      development_ports = ['3000', '5173']
      development_hosts = ['localhost', '127.0.0.1']

      origins_list += development_hosts.flat_map do |host|
        development_ports.map { |port| "http://#{host}:#{port}" }
      end
    end

    origins origins_list

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Set-Cookie', 'Authorization']
  end
end
