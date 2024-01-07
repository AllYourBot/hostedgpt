require "active_record/fixtures"

order_to_load_fixtures = %w[people users tombstones assistants conversations runs messages steps documents chats notes]

order_to_load_fixtures.each do |fixture_name|
  ActiveRecord::FixtureSet.create_fixtures("test/fixtures", fixture_name)
end

withchats = Person.new(email: "withchats@example.com")
withchats.personable = User.new(password: "hostedgpt", password_confirmation: "hostedgpt")
withchats.save!

nochats = Person.new(email: "nochats@example.com")
nochats.personable = User.new(password: "hostedgpt", password_confirmation: "hostedgpt")
nochats.save!

chat = Chat.create!(user: withchats.personable, name: "Create Rails Model: Note")
message = chat.notes.create!(content: "AuthenticatedController better name")
message.replies.create!(content: "For a more descriptive and intuitive name than AuthenticatedController, yet still conveying the essence of handling authenticated actions, consider:")
