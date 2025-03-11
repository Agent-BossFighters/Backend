class PaymentMailer < ApplicationMailer
  def payment_success_email(user)
    @user = user
    mail(to: @user.email, subject: 'Confirmation de votre paiement Premium')
  end

  def payment_canceled_email(user)
    @user = user
    mail(to: @user.email, subject: 'Annulation de votre abonnement Premium')
  end
end
