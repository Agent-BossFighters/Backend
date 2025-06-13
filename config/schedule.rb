set :output, "log/cron.log"

every 1.day, at: "4:30 am" do
  rake "sync:game_data"
end

every "0 0 1 * *" do
  command "cd /root/Backend && RAILS_ENV=production bundle exec rake users:reset_monthly_levels --silent >> log/cron.log 2>&1"
end
