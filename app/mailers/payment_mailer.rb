class PaymentMailer < ApplicationMailer
  def payment_succeeded_email(user)
    @user = user
    mail(to: @user.email, subject: 'Agent: Payment Successful 🎉')
  end

  def payment_canceled_email(user)
    @user = user
    mail(to: @user.email, subject: 'Agent: Subscription Canceled ❌')
  end

  def subscription_updated_email(user)
    @user = user
    mail(to: @user.email, subject: 'Agent: Subscription Updated 🔄')
  end

  def payment_failed_email(user)
    @user = user
    mail(to: @user.email, subject: 'Agent: Payment Failed ⚠️')
  end

  def payment_action_required_email(user)
    @user = user
    mail(to: @user.email, subject: 'Agent: Action Required to Complete Payment ⏳')
  end
end
