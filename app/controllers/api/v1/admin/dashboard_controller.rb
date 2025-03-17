class Api::V1::Admin::DashboardController < Api::V1::Admin::BaseController
  def index
    # Statistiques pour le tableau de bord d'administration
    render json: {
      users_count: User.count,
      premium_users_count: User.where(isPremium: true).count,
      matches_count: Match.count,
      nfts_count: Nft.count,
      currencies: {
        bft: Currency.find_by(symbol: 'BFT'),
        sponsor_marks: Currency.find_by(symbol: 'SM')
      },
      recent_users: User.order(created_at: :desc).limit(5),
      recent_matches: Match.order(created_at: :desc).limit(5)
    }
  end
end
