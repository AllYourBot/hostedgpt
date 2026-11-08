namespace :admin do
  desc "Make the user with the given email an admin"
  task :grant, [:email] => :environment do |t, args|
    person = Person.find_by(email: args[:email].to_s)
    abort "No user found with email #{args[:email].inspect}" unless person&.user

    person.user.update!(admin: true)
    warn "#{args[:email]} is now an admin"
  end
end
