class Currency < ApplicationRecord
  belongs_to :game
  has_many :currency_packs
  has_many :slots

  # Ajouter un callback après sauvegarde pour invalider le cache
  after_save :invalidate_rates_cache

  private

  def invalidate_rates_cache
    # Invalider le cache des taux de change
    DataLab::CurrencyRatesService.invalidate_cache
  end
end
