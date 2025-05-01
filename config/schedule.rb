set :output, "log/cron.log"

every 1.day, at: '4:30 am' do
  rake "sync:game_data"
end

every '0 0 1 * *' do 
  rake "users:reset_monthly_levels"
end