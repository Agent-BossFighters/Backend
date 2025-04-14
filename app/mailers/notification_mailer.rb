class NotificationMailer < ApplicationMailer
  default from: ENV['MAILJET_SENDER_EMAIL']

  def welcome_email(user)
    @user = user
    @url = 'https://agent-bossfighters.com/#/users/login'

    mail(
      to: @user.email,
      subject: 'Welcome to Agent-BossFighters!'
    )
  end

  def reset_password_instructions(user, token, _opts = {})
    @user = user
    @token = token
    @reset_url = "http://127.0.0.1:5173/#/users/password/reset?reset_password_token=#{token}"

    mail(
      to: @user.email,
      subject: 'Reset your password'
    )
  end
end
