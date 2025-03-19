class NotificationMailer < ApplicationMailer
  default from: ENV['MAILJET_SENDER_EMAIL']

  def welcome_email(user)
    @user = user
    @url = 'https://agent-bossfighters.com/login'

    mail(
      to: @user.email,
      subject: 'Welcome to Agent-BossFighters!'
    )
  end
end
