set :output, "log/cron.log"

every 1.day, at: '4:30 am' do
  rake "sync:game_data"
end
