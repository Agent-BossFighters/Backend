class NotificationMailer < ApplicationMailer
  default from: ENV['MAILJET_SENDER_EMAIL']

  def welcome_email(user)
    @user = user
    @url = 'https://votre-domaine.com/login'

    mail(
      to: @user.email,
      subject: 'Bienvenue sur Boss Fighters!'
    )
  end

  def match_summary(user, match)
    @user = user
    @match = match
    @url = "https://votre-domaine.com/matches/#{match.id}"

    mail(
      to: @user.email,
      subject: 'Résumé de votre match Boss Fighters'
    )
  end
end
