namespace :db do
  desc "Change fly VM"
  task :fly, [:app_name, :command, :detail] => :environment do |t, args|
    if args[:app_name].nil? || args[:command].nil? || args[:detail].nil?
      puts "Missing arguments. Call with bin/rails fly[APP_NAME,COMMAND,DETAIL]"
      return
    end

    if args[:command] == "swap"
      Fly.new.change_db_swap(app: args[:app_name], swap: args[:detail].to_i)
    else
      puts "Unrecognized command #{args[:command]}"
    end
  end
end
