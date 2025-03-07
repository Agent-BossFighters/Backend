class PaymentMailer < ApplicationMailer
  def payment_success_email(user)
    @user = user
    mail(to: @user.email, subject: 'Confirmation de votre paiement Premium')
  end
end
