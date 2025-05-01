namespace :users do
  desc "Réinitialise le niveau de tous les utilisateurs au début de chaque mois"
  task reset_monthly_levels: :environment do
    puts "Début de la réinitialisation des niveaux pour #{Date.current.strftime('%B %Y')}"
    
    total_users = User.count
    updated_users = 0
    
    User.find_each do |user|
      user.reset_monthly_level
      updated_users += 1
      
      if (updated_users % 100).zero?
        puts "Progression : #{updated_users}/#{total_users} utilisateurs traités"
      end
    end
    
    puts "Réinitialisation terminée. #{updated_users} utilisateurs ont été mis à jour."
  end
end