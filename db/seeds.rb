withchats = Person.new(email: "withchats@example.com")
withchats.personable = User.new(password: "hostedgpt", password_confirmation: "hostedgpt")
withchats.save!

nochats = Person.new(email: "nochats@example.com")
nochats.personable = User.new(password: "hostedgpt", password_confirmation: "hostedgpt")
nochats.save!

chat = Chat.create!(user: withchats.personable, name: "Create Rails Model: Note")
message = chat.notes.create!(content: "AuthenticatedController better name")
message.replies.create!(chat: chat, content: "For a more descriptive and intuitive name than AuthenticatedController, yet still conveying the essence of handling authenticated actions, consider:")
