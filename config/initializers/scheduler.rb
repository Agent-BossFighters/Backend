# Ce fichier configure les tâches planifiées pour l'application

# Ne pas exécuter les jobs lors du chargement des classes en développement ou en test
unless Rails.env.test? || (Rails.env.development? && $PROGRAM_NAME.include?("spring"))
  Rails.application.config.after_initialize do
    # Planifier la mise à jour des prix des crypto-monnaies
    if defined?(UpdateCryptoPricesJob) && Rails.application.config.respond_to?(:coinmarketcap)
      # Attendre 5 minutes après le démarrage de l'application pour commencer
      UpdateCryptoPricesJob.set(wait: 5.minutes).perform_later
    end
  end
end
