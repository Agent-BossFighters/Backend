class CryptoPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  def metamask
    begin
      # Vérifier la signature de la transaction
      tx_hash = params[:tx_hash]
      amount = params[:amount]
      currency_type = params[:currency_type]

      # Créer la transaction
      transaction = Transaction.create!(
        user: current_user,
        payment_method: PaymentMethod.find_by(provider: "metamask"),
        amount: amount,
        currency: "ETH",
        status: "pending",
        external_id: tx_hash,
        metadata: {
          currency_type: currency_type,
          network: params[:network]
        }
      )

      render json: {
        status: "pending",
        transaction: transaction
      }, status: :ok
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def verify
    begin
      tx_hash = params[:tx_hash]
      transaction = Transaction.find_by!(external_id: tx_hash)

      # Vérifier le statut de la transaction sur la blockchain
      # Ceci est un exemple, il faudra adapter selon la blockchain
      tx_status = Web3Service.verify_transaction(tx_hash)

      if tx_status == "confirmed"
        transaction.update(status: "completed")
        # Créditer le compte utilisateur
      end

      render json: {
        status: transaction.status,
        transaction: transaction
      }, status: :ok
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
