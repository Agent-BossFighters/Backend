namespace :sync do
  desc "Synchronize all data from OpenLoot"
  task openloot: :environment do
    puts "Starting OpenLoot synchronization..."
    DataSyncService.sync_all
    puts "OpenLoot synchronization completed!"
  end

  desc "Synchronize badges from OpenLoot"
  task badges: :environment do
    puts "Starting badges synchronization..."
    DataSyncService.new.sync_badges
    puts "Badges synchronization completed!"
  end

  desc "Synchronize contracts from OpenLoot"
  task contracts: :environment do
    puts "Starting contracts synchronization..."
    DataSyncService.new.sync_contracts
    puts "Contracts synchronization completed!"
  end
end

desc "Synchronize all external data"
task sync: [ "sync:openloot" ] do
  puts "All synchronization tasks completed!"
end
