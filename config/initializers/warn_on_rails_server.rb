if defined?(Rails::Server)
  if ENV["RAILS_ENV"] == "development" && ENV["USING_PROCFILE"] != "true"
    puts ""
    puts "###"
    puts "### WARNING: You're running 'rails server' outside of the Procfile. This fails to start SolidQueue and Tailwind."
    puts "###"
    puts "### Cancel this with Ctrl + c and instead run 'bin/dev'"
    puts "###"
    puts "### Full setup instructions are here: https://github.com/allyourbot/hostedgpt#contribute-as-a-developer"
    puts "### (Or, press Enter to proceed anyway)"
    puts "###"
    gets
  end
end